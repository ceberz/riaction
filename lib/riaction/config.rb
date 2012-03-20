module Riaction
 class Config

  # initialize the config settings for riaction
  # == Parameters:
  # orm::
  #   A Symbol declaring the orm to use.
  #   It can be `:active_record` or `:none`.
  #   default is `:none`
  def initialize(orm = :none)
    @orm = orm #change this to active_record
  end

  attr_accessor :orm
 end
end