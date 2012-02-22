namespace 'riaction' do
  namespace 'rails' do
    namespace 'list' do
      desc "List all registered events"
      task :events => :environment do
        Dir.glob(File.join(RAILS_ROOT,"app","models","*.rb")).each do |rbfile|
          require rbfile
        end
      
        Riaction::Riaction::EVENT_CLASSES.each do |class_name|
          klass = class_name.constantize
          puts "#{klass} defines the following events:"
          opts = klass.riaction_options
          klass.riaction_events.each_pair do |name, deets|
            puts " :#{name}:"
            if Riaction::Constants.crud_actions.include? deets[:trigger]
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
            
            case deets[:profile_type]
            when Symbol
              puts "    Profile Type: #{deets[:profile_type]}"
            when NilClass
              puts "    Profile Type: uses default"
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
            
            if opts[:default_event_params].present?
              case opts[:default_event_params]
              when Symbol
                puts "      Params included by default: Hash returned by :#{opts[:default_event_params]}"
              when Proc
                puts "      Params included by default: Hash returned via Proc"
              when Hash
                puts "      Params included by default: #{opts[:default_event_params]}"
              end
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
      
        Riaction::Riaction::PROFILE_CLASSES.each do |class_name|
          klass = class_name.constantize
          if (klass.riactionary? && klass.riaction_profile? && klass.riaction_profile_types_defined > 0)
            puts "Addressing #{class_name}: defines the profile(s) #{klass.riaction_profile_keys.keys.map(&:to_s).join(', ')}"
            klass.select(:id).all.each do |obj|
              puts "  Addressing record ##{obj.id};"
              ::Riaction::ProfileCreator.perform(class_name, obj.id)
            end
          end
        end
      end
      
      desc "Process a specified event on a specified class (requires EVENT_CLASS and EVENT_NAME)"
      task :event => :environment do
        klass_name = ENV['EVENT_CLASS']
        event_symbol = ENV['EVENT_NAME'].to_sym
        begin
          if klass_name.constantize.riaction_events.has_key? event_symbol
            klass_name.constantize.all.each do |record|
              if record.riaction_log_event? event_symbol
                profile_params = record.riaction_event_params[event_symbol][:profile]
                event_params = record.riaction_event_params[event_symbol][:params].stringify_keys
                
                IActionable::Api.new.log_event( profile_params[:type].to_s,
                                                profile_params[:id_type].to_s,
                                                profile_params[:id].to_s,
                                                ENV['EVENT_NAME'].to_s,
                                                event_params )
                puts "Logged #{ENV['EVENT_NAME']} for #{record.id}"
              else
                puts "Event could not be logged for id:#{record.id}"
              end
            end
          else
            puts "'#{ENV['EVENT_NAME']}' is not a valid event"
          end
        rescue NameError => e
          puts e
        end
      end
    
    end
  end
end
