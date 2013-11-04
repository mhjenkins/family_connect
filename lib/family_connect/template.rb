require "addressable/template"
module FamilyConnect
  class Template
    attr_accessor :client, :template, :type, :accept, :allow, :title

    def initialize args
      if args[:template].nil?
        raise FamilyConnect::Error::TemplateNotFound
      end
      @client = args[:client]
      @template = args[:template]["template"]
      @type = args[:template]["type"]
      @accept = args[:template]["accept"]
      @allow = args[:template]["allow"] || []
      @title = args[:template]["title"]
    end

    def get args={}
      raise FamilyConnect::Error::MethodNotAllowed unless validate_method "GET"
      make_request ({:params => args, :method => "GET"})
    end

    def post args={}
      raise FamilyConnect::Error::MethodNotAllowed unless validate_method "POST"
      #template_values = validate_values(template_values)
      #t = Addressable::Template.new(@template)
      #url = t.expand(template_values).to_s
      #@client.make_request({:url => t.to_s})
    end

    private

    def make_request args
      params = validate_values(args[:params])
      t = Addressable::Template.new(@template)
      url = t.expand(params).to_s
      @client.make_request({:url => url.to_s, :method => args[:method]})
    end

    def validate_method method
      @allow.include? method
    end

    def value_array
      template_value_array = []
      values = @template.scan(/\{([^}]*)\}/).flatten
      values.each do |value|
        value.gsub!('?', '')
        template_value_array += value.split(',')
      end
      template_value_array
    end

    def validate_values(template_values)
      vals = value_array
      stringified_hash = {}
      template_values[:access_token] = @client.access_token
      template_values.each do |k, v|
        stringified_hash[k.to_s] = v
        unless vals.include?(k.to_s)
          raise FamilyConnect::Error::TemplateValueNotFound
        end
      end

      raise FamilyConnect::Error::TemplateValueMissing if template_values.keys.map { |k| k.to_s.downcase } != vals
      stringified_hash
    end
  end
end