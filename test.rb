require File.join(File.dirname(__FILE__), 'search_engine')

class SearchController
  def search
    SearchEngine.search do
      # We will get undefined method 'params' for #<Query:123>
      # in this case
      keywords params[:q]
    end
  end # search

  def smart_search
    SearchEngine.search_with_context do
      # No error here. Magick!
      keywords params[:q]
    end
  end # smart_search

  def params
    { :q => 'Why Instance eval is evil' }
  end # params
end


# We would get error in this case
#puts SearchController.new.search

# No error in this case
puts SearchController.new.smart_search
