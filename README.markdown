WTF is this?
=============

Showing [Sunspot library](http://github.com/outoftime/sunspot) to different people I have noticed their confusion about Sunspot search API.
Sunspot provides the following API for search

    search = Sunspot.search(Post) do
      keywords "Mark Twain"
    end

And all rails developers try to do the following in the first place

	class SearchController < Application
	  def index
	    @search = Sunspot.search(Post) do
	      keywords params[:q]
	    end
	  end
	end

Pretty obvious, huh? But they are facing the problem, cause this code throws an exception

     undefined method 'params' for <Sunspot::Query>

Some of them are trying to do the following:

    def index
      query_string = params[:q]

      @search = Sunspot.search(Post) do
        keywords query_string
      end
    end

And everything works as expected. At this place many of them are starting to understand what Sunspot uses
instance_eval to provide this nice DSL.

instance_eval allows you to execute the block of the code in context of any object.
In context means if you do

    @object.instance_eval { puts self }

_self_ in the block will be an _@object_ itself.

Back to our sunspot problem. _params_ in Rails is actually a method on ActiveController::Base
so instance_eval on Suspot::Query object doesn't have it. The code with the local variable (2nd variant) is working because you have access to all variables deined in its lexical scope.

What to do with this "problem"? The idea was to catch the object in which block was created and pass
it to Query. Query is implementing _method_missing_ with fallback to the caught object. Everything works as expected. But we have 2 new problems.

  * How to get the caller object?
  * What to do if method not found neither in Query nor in caller object?

I've found the answer to first question inside the ruby [Kernel#eval](http://ruby-doc.org/core/classes/Kernel.html#M005922)
docs. _Kernel#eval_ accepts the special object of class [Binding](http://ruby-doc.org/core/classes/Binding.html) which incapsulates the
execution context at some place in the code (sounds like a continuation? yep) or objects of class _Proc_. (In Ruby 1.9 API have changed and _Kernel#eval_ accepts only objects of class Binding).

Actualy blocks are the objects of class _Proc_ (lambdas are Procs too). But I recomend to pass binding to keep compatibility with new shiny Ruby 1.9. Luckily for us there is a method  _Proc#binding_ which does the thing you expect. How to get required object from _Proc_ and _eval_? Really simple:

    eval 'self', block

The second question is open for discussion.

Now we know enough to implement "smart" instance_eval which can try to find missing methods in context in which block was created.

    def self.search_with_context(&blk)
      caller = eval('self, blk)

      QueryWithContext.new(caller).tap do |query|
        query.instance_eval(&blk)
      end
    end

Look in the sources for full implementation.
