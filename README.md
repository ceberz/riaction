# Overview #

riaction provides both a ruby wrapper for IActionable's restful API and an "acts-as" style interface for the models in your Rails application.  This document assumes knowledge of IActionable's API.

# How To Use #

## Installation ##

    gem install riaction

### Generators ###

Riaction comes with a generator for creating a YAML file to contain your credentials for each environment of your application.  The YAML file is necessary for riaction to run correctly in your rails app.

    rails g riaction development:12345:abcde production:54321:edcba

### Declaring A Model As A Profile ###

Models in your application may declare themselves as profiles that exist on IActionable.

    class User < ActiveRecord::Base
      riaction :profile, :type => :player, :username => :nickname, :custom => :id
    end
    
    # == Schema Information
    #
    # Table name: users
    #
    #  id                           :integer(4)
    #  nickname                     :string(255)
  
Here, the class User declares itself as a profile of type "player", identifiable by two of IActionable's supported identifier types, username and custom.  The values of these identifiers are the fields nickname and id, respectively, and can be any method that an instance of the class responds to.  When a class declares itself as a riaction profile, an after_create callback will be added to create the profile on IActionable with the identifiers declared in the class.

An optional display name can be given, which should be a method that the object responds to:

    class User < ActiveRecord::Base
      riaction :profile, :type => :player, :username => :nickname, :custom => :id, :display_name => :nickname
    end
  

#### Profile Instance Methods ####

Classes that declare themselves as IActionable profiles are given instance methods that tie in to the IActionable API, as many uses of the API treat the profile as a top-level resource.

    @api.get_profile_summary("player", "username", "zortnac", 10)
    # is equivalent to the following...
    @user_instance.riaction_profile_summary(10)
    
    @api.get_profile_challenges("player", "username", "zortnac", :completed)
    # is equivalent to the following...
    @user_instance.riaction_profile_challenges(:completed)
    
    @api.add_profile_identifier("player", "username", "zortnac", "custom", 42)
    # is equivalent to the following...
    @user_instance.riaction_update_profile(:custom)

### Declaring Events ###

Models in your application may declare any number of events that they wish to log through IActionable.  For each event that is declared the important elements are:

* The event's name (or key).
* The type of trigger that causes the event to be logged.
* The profile under which the event is logged.
* Any optional parameters (key-value pairs) that you want to pass.

<!-- end list --> 

    class Comment
      belongs_to :user
      belongs_to :post
      
      riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :params => {:post => :post_id}
    end
    
    # == Schema Information
    #
    # Table name: comments
    #
    #  id                           :integer(4)
    #  user_id                      :integer(4)
    #  post_id                      :integer(4)

Here, the name of the event is `make_a_comment`.  The trigger for the event, in this case, is `:create`, which will add an after_create callback to log the event to the API.  

_Note: If the trigger is one of :create, :update, or :destroy, then the appropriate ActiveRecord callback will log the event.  If the trigger is anything else, then an instance method is provided to log the event by hand.  For example, an argument of `:trigger => :foo` will provide an instance method `trigger_foo!`_

The profile that this event will be logged under can be any object whose class declares itself as a profile.  Here, the profile is the object returned by the ActiveRecord association `:user` (for this example we assume this is an instance of the User class from above).  Lastly, the optional params passed along with the event is the key-value pair `{:post => :post_id}`, where `:post_id` is an ActiveRecord table column.

Putting this all together, whenever an instance of the Comment class is created, an event is logged for which the equivalent call to the API might look like this:

    @api.log_event("player", "username", "zortnac", "make_a_comment", {:post => 33})

_Note: If a class declares itself as a profile and also declares one or more events, but wants to refer to itself as the profile for any of those events, use `:profile => :self` in the event's declaration_

### Rails Rake Tasks ###

There are 3 rake tasks included for summarizing all of your models' declarations as well as a way to initialize profiles on IActionable.  To see a report of all the events declared across your application, run the following:

    rake riaction:rails:list:events

To see a report of all the profiles declared across your application, run the following:

    rake riaction:rails:list:profiles

Finally, to process all of the models in your application that declare themselves as profiles and initialize them on IActionable (for instance if you've added IActionable to an existing application with an established user base), run the following:

    rake riaction:rails:process:profiles

----------------

## IActionable ##

[Visit their website!](http://www.iactionable.com)

## Author ##

Christopher Eberz; chris@chriseberz.com; @zortnac