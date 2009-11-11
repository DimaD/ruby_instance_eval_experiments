module SearchEngine
  class Query
    def keywords(string)
      @keywords = string
    end # keywords

    def to_s
      "Query: #{@keywords}"
    end # to_s
  end

  class QueryWithContext < Query
    def initialize(context)
      @context = context
    end # initialize(caller)

    def method_missing(method_name, *args, &block)
      # I am not sure who should throw an error in case
      # there is no method in @context.
      # It maybe confusing to receive error:
      #   undefined method 'method_name' for <ContextClassName:<id>>
      # because a programmer can make an error in our API
      @context.__send__(method_name, *args, &block)
    end # method_missing
  end # QueryWithProperIE

  def self.search(&blk)
    Query.new.tap do |query|
      query.instance_eval(&blk)
    end
  end # self.search(&blk)

  def self.search_with_context(&blk)
    caller = get_caller_object_from_block(blk)

    QueryWithContext.new(caller).tap do |query|
      query.instance_eval(&blk)
    end
  end # self.search_with_context(&blk)

  private
  def self.get_caller_object_from_block(blk)
    # Black magick with Ruby internals
    eval 'self', blk.binding
  end # self.get_caller_obbject_from_block
end # SearchEngine

