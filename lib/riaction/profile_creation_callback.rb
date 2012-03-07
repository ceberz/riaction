require "resque"
require 'riaction/profile_creator'

module Riaction
  class ProfileCreationCallback

  	# Enqueue a Riaction::ProfileCreatore object in resque 
    def after_create(record)
      Resque.enqueue(::Riaction::ProfileCreator, record.class.base_class.to_s, record.id) unless record.class.riactionless?
    end                                 
  end
end