require "resque"
require 'riaction/event_performer'

module Riaction
  class CrudEventCallback
    def initialize(event_name)
      @event_name = event_name
    end

    # Enqueues a Riaction::EventPerformer object in resque after a model has been created
    def after_create(record)
      if record.riaction_log_event?(@event_name) && !record.class.riactionless?
        Resque.enqueue(::Riaction::EventPerformer, @event_name, record.class.base_class.to_s, record.id)
      end
    end                                 

    # Enqueues a Riaction::EventPerformer object in resque after a model has been updated
    def after_update(record)            
      if record.riaction_log_event?(@event_name) && !record.class.riactionless?
        Resque.enqueue(::Riaction::EventPerformer, @event_name, record.class.base_class.to_s, record.id)
      end
    end

    # Enqueues a Riaction::EventPerformer object in resque after a model has been destroyed
    def after_destroy(record)
      if record.riaction_log_event?(@event_name) && !record.class.riactionless?
        Resque.enqueue(::Riaction::EventPerformer, @event_name, record.class.base_class.to_s, record.id)
      end
    end
  end
end