RSpec::Matchers.define :define_riaction_profile do |expected_type|
  chain :identified_by do |identifiers|
    @identifiers = identifiers
  end
    
  match do |actual|
    if actual.riactionary? && actual.riaction_profile? && actual.riaction_profile_keys.has_key?(expected_type)
      if @identifiers.present?
        if @identifiers.select{|id_type, id|  actual.riaction_profile_keys[expected_type][:identifiers].has_key?(id_type) &&
                                              actual.riaction_profile_keys[expected_type][:identifiers][id_type] == id}.size == @identifiers.size
          true
        else
          false
        end
      else
        true
      end
    else
      false
    end
  end
  
  failure_message_for_should do |actual|
    if @identifiers.present?
      "expected that #{actual} would define a riaction profile of type #{expected_type} with identifiers #{@identifiers.keys.join(", ")}"
    else
      "expected that #{actual} would define a riaction profile of type #{expected_type}"
    end
  end
end

RSpec::Matchers.define :identify_with_riaction_as do |expected_type, expected_ids|
  match do |actual|
    if  actual.class.riactionary? && 
        actual.class.riaction_profile? && 
        actual.riaction_profile_keys.has_key?(expected_type) &&
        expected_ids.select{|id_type, id| actual.riaction_profile_keys[expected_type].fetch(id_type, nil) == id}.size == expected_ids.size
      true
    else
      false
    end
  end
  
  failure_message_for_should do |actual|
    "expected that instance of #{actual.class} would use the value(s) #{expected_ids} to identify to IActionable"
  end
end

RSpec::Matchers.define :define_riaction_event do |expected_event|
  chain :triggered_on do |expected_trigger|
    @expected_trigger = expected_trigger
  end
    
  match do |actual|
    if actual.riactionary? && actual.riaction_events? && actual.riaction_events.has_key?(expected_event)
      if @expected_trigger.present?
        if actual.riaction_events[expected_event][:trigger] == @expected_trigger
          true
        else
          false
        end
      else
        true
      end
    else
      false
    end
  end
  
  failure_message_for_should do |actual|
    if @expected_trigger.present?
      "expected that #{actual} would define a riaction event named #{expected_event} triggered on #{@expected_trigger}"
    else
      "expected that #{actual} would define a riaction event named #{expected_event}"
    end
  end
end

RSpec::Matchers.define :log_riaction_event_with_profile do |expected_event, expected_profile_type, expected_profile_id_type, expected_profile_id|
  match do |actual|
    if  actual.class.riactionary? && 
        actual.class.riaction_events? && 
        actual.riaction_event_params.has_key?(expected_event) &&
        actual.riaction_event_params[expected_event][:profile][:type] == expected_profile_type &&
        actual.riaction_event_params[expected_event][:profile][:id_type] == expected_profile_id_type &&
        actual.riaction_event_params[expected_event][:profile][:id] == expected_profile_id
      true
    else
      false
    end
  end
  
  failure_message_for_should do |actual|
    "expected that instance of #{actual.class} would log event #{expected_event} with the profile keys: #{expected_profile_type}, #{expected_profile_id_type}, #{expected_profile_id}"
  end
end

RSpec::Matchers.define :log_riaction_event_with_params do |expected_event, expected_params|
  match do |actual|
    if  actual.class.riactionary? && 
        actual.class.riaction_events? && 
        actual.riaction_event_params.has_key?(expected_event) &&
        actual.riaction_event_params[expected_event][:params] == expected_params
      true
    else
      false
    end
  end
  
  failure_message_for_should do |actual|
    "expected that instance of #{actual.class} would log event #{expected_event} with params #{expected_params}"
  end
end
