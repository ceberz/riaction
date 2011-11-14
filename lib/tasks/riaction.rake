namespace 'riaction' do
  namespace 'rails' do
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

      desc "List all achievments defined on IActionable"
      task :achievements => :environment do
        api = IActionable::Api.new
        achievements = api.get_achievements
        unless achievements.empty?
          achievements.each do |achievement|
            puts achievement.key
            puts "  Name: #{achievement.name}"
            puts "  Image: #{achievement.image_url}"
            puts "  Description: #{achievement.description}"
            puts "-------------------------------------------------------"
          end
        else
          puts "No achievements defined."
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
              declaration = klass.riaction_profiles.first
              puts "Addressing #{klass} record #{obj.id}; creating profile under type '#{declaration[0]}'"
              obj.riaction_create_profile
              default_keys = obj.riaction_profile_keys(declaration[0])
              declaration[1].each_pair do |id_type, id|
                value = obj.send(id)
                puts "...updating profile with id type #{id_type} and value #{value}"
                obj.riaction_update_profile(id_type)
              end
            end
          rescue Riaction::NoProfileDefined => e
            puts "ERROR: #{klass} does not properly define a profile; skipping"
          end
        end
      end
    end
  end
end
