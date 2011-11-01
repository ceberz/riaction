namespace 'iactionable' do
  namespace 'list' do
    desc "List all registered events"
    task :events => :environment do
      Dir.glob(File.join(RAILS_ROOT,"app","models","*.rb")).each do |rbfile|
        require rbfile
      end
      
      Riaction::EVENT_LOGGING_CLASSES.each do |klass|
        puts "#{klass} defines the following events:"
        klass.riaction_events.each_pair do |name, deets|
          puts " :#{name}:"
          if Riaction.crud_actions.include? deets[:trigger]
            puts "    Trigger: Fired on ActiveRecord after_#{deets[:trigger]} callback"
          else
            puts "    Trigger: By calling :trigger_#{deets[:trigger]}!"
          end
          case deets[:profile]
          when Symbol
            if deets[:profile] == :self
              puts "    Profile: (self)"
            else
              puts "    Profile: Value returned by :#{deets[:profile]}"
            end
          when Proc
            puts "    Profile: Returned via Proc"
          end
          case deets[:params]
          when NilClass
            puts "    Event Params: None"
          when Symbol
            puts "    Event Params: Hash returned by :#{deets[:params]}"
          when Proc
            puts "    Event Params: Hash returned via Proc"
          when Hash
            puts "    Event Params: #{deets[:params]}"
          end
          case deets[:guard]
          when NilClass
            puts "    Guard: None"
          when Proc
            puts "    Guard: Boolean returned via Proc"
          when Hash
            puts "    Guard: Boolean returned by :#{deets[:guard]}"
          end
          puts ""
        end
        puts "-------------------------------------------------------"
      end
    end

    desc "List all registered profiles"
    task :profiles => :environment do
      Dir.glob(File.join(RAILS_ROOT,"app","models","*.rb")).each do |rbfile|
        require rbfile
      end
      
      Riaction::PROFILE_CLASSES.each do |klass|
        puts "#{klass} defines the following profile types:"
        klass.riaction_profiles.each_pair do |type, ids|
          puts " :#{type}:"
          puts "    With the following ID types, and field used for the value:"
          ids.each_pair do |id_type, id|
            puts "      :#{id_type} => :#{id}"
          end
          puts ""
        end
        puts "-------------------------------------------------------"
      end
    end
  end
  
  namespace 'process' do
    desc "Run through all classes acting as profiles and make sure each record/instance exists on IActionable"
    task :profiles => :environment do
      Dir.glob(File.join(RAILS_ROOT,"app","models","*.rb")).each do |rbfile|
        require rbfile
      end
      
      Riaction::PROFILE_CLASSES.each do |klass|
        begin
          klass.all.each do |obj|
            puts "Addressing #{klass} record #{obj.id}..."
            klass.riaction_profiles.each_pair do |type, ids|
              puts "...creating profile under type '#{type}'"
              obj.riaction_create_profile(type)
              default_keys = obj.riaction_profile_keys(type)
              ids.each_pair do |id_type, id|
                value = obj.send(id)
                puts "...updating profile with id type #{id_type} and value #{value}"
                obj.riaction_update_profile(type, default_keys[:profile_type], id_type)
              end
            end
          end
        rescue IAction::Error::NoProfileDefined => e
          puts "ERROR: #{klass} does not properly define a profile; skipping"
        end
      end
    end
  end
end
