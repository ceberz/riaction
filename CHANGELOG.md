# CHANGELOG #

## 1.3.1 ##

* re-naming the methods added in v1.3.0

## 1.3.0 ##

* Added new feature to have a riaction profile class return the raw json from the IActionable API instead of the objects they get wrapped in by ruby-iactionable gem

## 1.2.7 ##

* Fixed a bug where the event parameters on the instance of class defining multiple events raises an error when one of those events does not point to a valid profile. Now, that event will simply be missing from the returned event parameters.  Attempting to log an event that does not point to a valid profile will raise the appropriate error.
* riaction:rails:process:event task relies on rake-style arguments instead of shell variables.

## 1.2.6 ##

* resque jobs will re-enqeue on a timeout error

## 1.2.5 ##

* fixing bug with optional display name argument in profiles

## 1.2.4 ##

* fixing argument error in riaction.rb

## 1.2.3 ##

* Fixing bug with default params for riaction events not being evaluated correctly as methods
* Multiple calls to setting the default params will merge, and not replace one-another

## 1.2.2 ##

* Fixed bug in event performer when perform() received event name as a string rather than a symbol

## 1.2.1 ##

* Added rake task to run an event on all records in a class

## 1.2.0 ##

* Added rspec matchers
* rake task to list all defined events also shows default params

## 1.1.0 ##

* Entire re-spec and re-factor of gem
* A class may declare multiple profile types
* Events may specify which profile type of a profile object to use when firing event
* Backwards-compatible with previous version 

## 1.0.0 ##

* API return values are now all objects, not mix of key/value pairs and objects.
* Objects turn themselves back in to original key/value data from IActionable.

## 0.5.1 ##

* Fixed bug preventing profile updates.

## 0.5.0 ##

* Added ability to specify a display name for a profile.  new feature; all existing features work the same.


## 0.4.2 ##

* Fixed NameError bug in tasks. For realsies.

## 0.4.1 ##

* Fixed NameError bug in tasks.

## 0.4.0 ##

* Adding calls to the profile interface for fetching and updating points

## 0.3.0 ##

* re-organized module and got rid of a memory leak that showed up in Rails apps running with cache\_classes set to false

## 0.2.1 ##

* Fixed problematic load order of the IActionable objects

## 0.2.0 ##

* Generator added to create YAML file for IActionable credentials

## 0.1.1 ##

* Rake task `riaction:rails:list:achievements` produces formatted output of all achievements defined on IActionable
* Change log

## 0.1.0 ##

* Resque jobs that make requests to IActionable will try up to 3 times on the event of a 500 response from IActionable