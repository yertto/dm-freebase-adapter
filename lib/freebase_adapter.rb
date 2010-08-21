require 'dm-core'
require 'json'
require 'net/http'
require 'pp'


# Don't know whether to do this with multiple repositories, or child_keys or
# parent_keys or fields, but for now, I just need to get the thing to work so I
# can start building things on top of it.  So my quick fix is to monkey patch
# relationships to look after incoming metaweb properties
module DataMapper
  module Associations
    class Relationship
      alias :_initialize :initialize
      def initialize(name, child_model, parent_model, options = {})
        @incoming_prop = options.delete(:incoming_prop)
        _initialize(name, child_model, parent_model, options)
      end
      def incoming_prop
        # XXX - grrr why won't this work! - XXX
        #@incoming_prop
        # XXX - grrr why won't this work! - XXX
        # XXX I can *see* the incoming_prop attribute when I "inspect" the actor relationship on performance,
        # XXX but I can't get to it, so enter this nasty hack for now...
        @incoming_prop || inspect.scan(/@incoming_prop="(.+?)"/).first[0]
      end
    end
  end
end


module DataMapper
  module Adapters
    class FreebaseAdapter < AbstractAdapter

      #FREEBASE_HOST = "www.freebase.com"
      #FREEBASE_HOST = "sandbox.freebase.com"
      FREEBASE_HOST = ENV['LIVE'] ? "www.freebase.com" : "sandbox.freebase.com"
      FREEBASE_PATH = "/api/service/mqlread"

      def read(query)
        p query.model if ENV['DEBUG']

        fields = query.fields
        p fields if ENV['DEBUG']

        metaweb_query = {}

        target_fields = fields.inject({}) { |h, field|
          key = field.name
          p key if ENV['DEBUG']
          h[key] = nil unless key.to_s[-3..-1] == '_id'
          h
        } 


        multi_key = false

        operands = query.conditions.operands.to_a
        if operands.size == 1 and !operands.first.subject.is_a? DataMapper::Associations::Relationship
          # Top level query
          p 'here0', target_fields if ENV['DEBUG']
          sort = build_metaweb_sort_directive(query.order)
          target_fields["sort"] = sort if sort.size > 0
          metaweb_query.update(target_fields)
          query.conditions.each { |condition|
            key = build_metaweb_condition_key(condition)
            metaweb_query[key] = condition.value
          }
          metaweb_query[:type] = query.model.storage_names[:freebase_repo]
          result = metaweb_query_result([metaweb_query])
          result = [result].flatten
        else
          p 'Association query' if ENV['DEBUG']
          incoming_prop = nil
          query.conditions.each { |condition|
            case condition.subject
            when DataMapper::Associations::ManyToOne::Relationship
              p 'here1' if ENV['DEBUG']
              # XXX - need to get this from somewhere else ... but *where*!
              inv_relationship = condition.subject.parent_model.relationships[
                DataMapper::NamingConventions::Resource::UnderscoredAndPluralized.call(query.model.name)
              ]
              inv_relationship = condition.subject.parent_model.relationships[
                DataMapper::NamingConventions::Resource::Underscored.call(query.model.name)
              ] unless inv_relationship
              #p inv_relationship if ENV['DEBUG']
              incoming_prop = inv_relationship.incoming_prop
              p incoming_prop if ENV['DEBUG']
              # XXX - need to get this from somewhere else ... but *where*!
              target_fields.delete(condition.subject.child_key.first.name)  # remove the parental link
              if condition.value.is_a? Array
                multi_key = true
                metaweb_query[:'id|='] = condition.value.collect(&:id)
              else
                metaweb_query[:id] = condition.value.id
              end
            else
              p 'here2' , condition.value if ENV['DEBUG']
              key = build_metaweb_condition_key(condition)
              if condition.is_a? DataMapper::Query::Conditions::InclusionComparison
                key = condition.subject.name
                val = [{"id|=" => condition.value.collect { |x| x.id }}]
                p 'here2a' , val if ENV['DEBUG']
              elsif key == condition.subject.name
                v = condition.value
                v = v.id if v.is_a? DataMapper::Resource
                val = {"id" => v}
              else
                val = condition.value
              end
              target_fields[key] = val
            end
          }
          sort = build_metaweb_sort_directive(query.order)
          target_fields["sort"] = sort if sort.size > 0
          target_fields[:limit] = query.limit || 350 # XXX - I think the freebase default is 100
          metaweb_query[incoming_prop] = [target_fields]
          metaweb_query = [metaweb_query] if multi_key
          result = metaweb_query_result(metaweb_query)
          if multi_key
            result = result ? result.collect {|x| x[incoming_prop]}.flatten : []
          else
            result = result ? result[incoming_prop] : []
          end
        end
        puts "here3 #{result.inspect}" if ENV['DEBUG']
        result
      end

      private

      def build_metaweb_condition_key(condition)
        case condition
        when DataMapper::Query::Conditions::LikeComparison
          "#{condition.subject.name}~="
        when DataMapper::Query::Conditions::InclusionComparison
          "#{condition.subject.name}|="
        when DataMapper::Query::Conditions::LessThanComparison
          "#{condition.subject.name}<"
        when DataMapper::Query::Conditions::GreaterThanComparison
          "#{condition.subject.name}>"
        when DataMapper::Query::Conditions::LessThanOrEqualToComparison
          "#{condition.subject.name}<="
        when DataMapper::Query::Conditions::GreaterThanOrEqualToComparison
          "#{condition.subject.name}>="
        when DataMapper::Query::Conditions::NotOperation
          "#{condition.operands.first.subject.name}!="
        else
          condition.subject.name
        end
      end

      def query_url
        host = (options[:host] && !options[:host].empty?) ? options[:host] : FREEBASE_HOST
        path = (options[:path] && !options[:path].empty?) ? options[:path] : FREEBASE_PATH
        "http://#{ host }#{ path }"
      end

      def build_metaweb_sort_directive(directions)
        directions.reject { |order| order.target.name.to_s == "id" }.collect do |direction|
          sort = direction.target.name
          sort = "-#{sort}" if direction.operator == :desc
          sort
        end
      end

      def metaweb_query_result(query)
        JSON.parse(metaweb_read(query))["result"]
      end

      def metaweb_read(query)
        puts "QUERY:" if ENV['DEBUG']
        puts "#{JSON.dump(query)}" if ENV['DEBUG']
        metaweb_query = "?query={\"query\": #{JSON.dump(query)}}"
        url = "#{query_url}#{URI.escape(metaweb_query)}"
        response = Net::HTTP.get_response(URI.parse(url))
        response.body
      end

    end # class FreebaseAdapter
  end # module Adapters
end # module DataMapper

