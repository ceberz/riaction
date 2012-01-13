# CHANGELOG #

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