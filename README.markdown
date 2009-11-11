WTF is this?
=============

During showing [Sunspot library](http://github.com/outoftime/sunspot) to different people I have noticed their confusing with Sunspot search API.
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

instance_eval allow you to execute the block of code in context of any object.
In context means if you do

    @object.instance_eval { puts self }

_self_ in the block will be an _@object_ itself.

Back to our sunspot problem. _params_ in Rails is actually a method on ActiveController::Base
so instance_eval on Suspot::Query object don't have it. And the variant with local variable defined
before block is working because block is capturing local scope variables of it's creation.

What to do with this "problem"? The idea was to catch the object in which block was created and pass
it to Query which is implementing _method_missing_ with fallback to the caught object. But how to get this object?

I found solution inside the ruby [Kernel#eval](http://ruby-doc.org/core/classes/Kernel.html#M005922)
docs. _eval_ accepts the special object of class [Binding](http://ruby-doc.org/core/classes/Binding.html) which incapsulates the
execution context at some place in the code (sounds like a continuation? yep) or objects of class _Proc_. And blocks are the objects of class _Proc_ (and procs have a method _#binding_ which do the thing you expect). How to get required object from _Proc_ and _eval_? Really simple:

    eval 'self', block

And now we have everything to implement "smart" instance_eval which have a _method_missing_ fallback in the context of original object. Look in the code for implementation.
