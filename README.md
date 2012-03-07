# Overview #

You've [gamified](http://en.wikipedia.org/wiki/Gamification) your Rails app using IActionable's services, or maybe you're thinking about it.  IActionable offers a restful API to log events from your game; these events ("sign in", "write a review", etc) earn points, achievements and more for the users that perform them.  This gem provides a way to tie these events to the CRUD actions of the ActiveRecord models that make up your restful Rails app.  Through an "acts-as" style mix-in, riaction takes the "write a review" event defined in your IActionable game, and drives it with the actual creation of a review object.  Riaction makes use of the [Ruby-IActionable gem](https://github.com/zortnac/Ruby-IActionable) to connect to the IActionable API.

# How To Use #

## Installation ##

    gem install riaction

## Requirements and Dependencies ##

Riaction uses [Resque](https://github.com/defunkt/resque) to schedule and perform all requests to IActionable.

### Generators ###

Riaction comes with a generator for creating a YAML file to contain your credentials for each environment of your application.  The YAML file is necessary for riaction to run correctly in your rails app.

    rails g riaction development:12345:abcde production:54321:edcba

### Declaring A Model As A Profile ###

In IActionable's API, events are explicitly tied to the user that generated them; an event cannot exist or be logged that doesn't belong to a user.  In order to log an event for writing a review, we need to decide which model in our application will behave as the "profile" in IActionable's system.  Here our user model will serve that purpose:

    class User < ActiveRecord::Base
      riaction :profile, :type => :player, :custom => :id
    end
    
    # == Schema Information
    #
    # Table name: users
    #
    #  id                           :integer(4)
    #  nickname                     :string(255)
  
In the above example, the class User declares itself as a profile of type "player".  Profile types are defined on IActionable's account dashboard. Profiles are identifiable by a number of supported identifier types, and in the above example we'll be relying on the "custom" identifier type, which will point to the value of the model's unique key in the database.  In other words, the user in our Rails app with an id of 7 will map to a profile on IActionable of type "player", and a "custom" identifier with a value of "7."

By declaring our user class as a riaction profile, an after-create callback will be registered on the class to create the corresponding profile on IActionable.

IActionable's profiles also have a "display name" property which can also be given here, and which should be a method that the object responds to:

    class User < ActiveRecord::Base
      riaction :profile, :type => :player, :custom => :id, :display_name => :nickname
    end  

#### Profile Instance Methods ####

Classes that declare themselves as riaction profiles are given instance methods that hit various points in the IActionable API for loading a profile's data from the game, using the [Ruby-IActionable gem](https://github.com/zortnac/Ruby-IActionable).

    @user_instance = User.first
    
    # return the user's profile summary and (up to) 10 of their recent achievements
    @user_instance.riaction_profile_summary(10)
    
    # return the user's summary of challenges, limited to the ones already completed
    @user_instance.riaction_profile_challenges(:completed)

#### Multiple Profile Types ####

Riaction will support a model in your app to map to multiple profiles defined in IActionable, if your situation calls for that:

    class User < ActiveRecord::Base
      riaction :profile, :type => :light_world_player, :custom => :id
      riaction :profile, :type => :dark_world_player, :custom => :id
    end
    
    # == Schema Information
    #
    # Table name: users
    #
    #  id                           :integer(4)
    #  nickname                     :string(255)

In the above example we want to define our user model as two types of players in our (apparently Zelda-inspired) game.  The model will behave exactly as it would with only a single profile declared, and the first one declared ( `:light_world_player` ) will always be the default used, unless a different profile type is set explicitly:

    @user_instance.riaction_set_profile(:dark_world_player)

Setting the profile type only affects the instance it is called on, and the change will persist for the life of the object or until changed again.

### Declaring Events ###

Models in your application may declare any number of events that they wish to log through IActionable.  Just as an event on IActionable must belong to a profile, in this example the model generating the event belongs to the model that behaves as a profile:

    class Review
      belongs_to :user
      
      riaction :event, :name => :write_a_review, :trigger => :create, :profile => :user
      
      def length
        text.size
      end
      
      def stats
        {
          :length => text.length,
          :rating => stars
        }
      end
    end
    
    # == Schema Information
    #
    # Table name: comments
    #
    #  id                           :integer(4)
    #  user_id                      :integer(4)
    #  stars                        :integer(4)
    #  text                         :string(255)

In the above example: 

* `:write_a_review` is the name of the event and should match the key used on IActionable.  
* The value for `:trigger` determines the action that will cause the event to fire, and can also be `:update` or `:destroy`, and will automatically fire when a record is created, updated, or destroyed, respectively.
* **If the value for `:trigger` is not given, `:create` will be assumed.**
* The value given to `:profile` should return the riaction profile object that this event will be logged under.

<!-- end list -->

#### Event Parameters ####

Part of the power in the way IActionable may be configured to process your events is in the key-value parameters you can send along with the event itself.  Riaction allows you to define an event with these parameters.  Parameters may be a hash with static values:

    riaction :event, :name => :write_a_review, :trigger => :create, :profile => :user, :params => {:foo => 'bar'}

...a hash where some values reference methods:

    riaction :event, :name => :write_a_review, :trigger => :create, :profile => :user, :params => {:review_length => :length}

...a proc:

    riaction :event, :name => :write_a_review, :trigger => :create, :profile => :user, :params => Proc.new{|record| {:length => record.text.length}}

...or the name of an instance method (which ought to return a hash):

    riaction :event, :name => :write_a_review, :trigger => :create, :profile => :user, :params => :stats

#### Conditional Events ####

The logging of an event may be conditional:

    riaction :event, :name => :write_a_review, :trigger => :create, :profile => :user, :if => Proc.new{|record| record.stars > 3}

...where the value of `:if` may be an instance method or a proc.

### Things To Note ###

#### Non-CRUD Actions ####

Sometimes when create, update, and destroy just don't really make sense for the event, custom triggers may be declared:

    riaction :event, :name => :receive_thumbs_up, :trigger => :thumbs_up, :profile => :user

In the above example, in order to have the review fire an event when it gets a thumbs up from another user, we declare a trigger called `:thumbs_up`.  Since this won't be fired automatically like a CRUD action, an instance method will be provided to fire it by hand:

    @review_instance.trigger_thumbs_up!

#### Events and Multiple Profile Types ####

If the object given as the riaction profile for an event defines more than one profile type, the default profile type (the first one declared in the class) will be used.  To use a different one, pass in the name of the alternate type:

    riaction :event, :name => :write_a_review, :trigger => :create, :profile => :user, :profile_type => :dark_world_player

#### Profiles With Their Own Events ####

A class that declares itself as a profile may also declare events, and for those events it may point to itself as the profile to use:

    riaction :profile, :type => :player, :custom => :id
    riaction :event, :name => :join_the_game, :trigger => :create, :profile => :self

In the above example of a declaration on the User class, the user will fire a `:join_the_game` event using itself as the profile upon its creation.  _The profile declaration must come before the event declaration._

#### Turning Riaction Off ####

If you want to avoid the automatic creation of a profile, or the automatic logging of an event, classes that declare themselves as riaction profiles or event drivers provide a method to disable those automatic events:

    User.riactionless{ User.create(:nickname => 'zortnac') }                    # won't create the profile for the newly created user
    Review.riactionless{ @user_instance.reviews.create(:text => "loved it!") }  # won't fire the 'write_a_review' event
    Review.riactionless{ @review_instance.trigger_thumbs_up! }                  # won't fire the 'receive_thumbs_up' event

### Rails Rake Tasks ###

There are 3 rake tasks included for summarizing all of your models' declarations as well as a way to initialize profiles on IActionable.  To see a report of all the events declared across your application, run the following:

    rake riaction:rails:list:events

To see a report of all the profiles declared across your application, run the following:

    rake riaction:rails:list:profiles

To process all of the models in your application that declare themselves as profiles and initialize them on IActionable (for instance if you've added IActionable to an existing application with an established user base), run the following:

    rake riaction:rails:process:profiles

To run a specific event on all instances off a class that define that event:

    rake riaction:rails:process:event['ClassName', :event_name]

----------------

## IActionable ##

[Visit their website!](http://www.iactionable.com)

## Tested Ruby Versions
riaction has been tested on major releases of ruby 1.9.2 and ruby 1.9.3-p125.  If you find something please file a bug https://github.com/zortnac/riaction/issues

## Authors ##

Christopher Eberz; chris@chriseberz.com; @zortnac

Katie Miller; kmiller@elctech.com

Nicholas Audo; naudo@naudo.de; @naudo