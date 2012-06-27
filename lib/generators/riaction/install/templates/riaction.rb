# When the IActionable API returns a 500 for logging an event or creating a profile, a custom handler can be defined below,
# useful for making calls to external exception notifier services (airbrake, etc), or handling the failure in some specific way
# useful to the application.
# 
# ::Riaction::EventPerformer.handle_api_failure_with do |exception, event_name, class_name, id|
#   # re-raise the exception
#   raise exception
#   # return true to have the event rescheduled
#   true
#   # return false to not have the event rescheduled 
#   false
# end
# 
# ::Riaction::ProfileCreator.handle_api_failure_with do |exception, class_name, id|
#   # re-raise the exception
#   raise exception
#   # return true to have the event rescheduled
#   true
#   # return false to not have the event rescheduled 
#   false
# end