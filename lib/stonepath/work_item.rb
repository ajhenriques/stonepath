# The WorkItem is the center of this framework.  It is the thing that has a workflow,
# is the subject of ownership and tasks.  Tis is the place the primaey state machine will
# exist

require 'aasm'
require 'stonepath/event_logging'
require 'stonepath/dot'


module StonePath
  module WorkItem
    def self.included(base)
      base.instance_eval do
        include AASM
        extend StonePath::EventLogging
        extend StonePath::Dot

        def owned_by(owner, options={})
          options.merge!(:class_name => owner.to_s.classify)
          belongs_to :owner, options
        end

        def tasked_through(tasks, options={})
          options.merge!(:as => :workitem)
          has_many tasks, options
        end

        def state_machine(options={}, &block)
          aasm_options = {:whiny_transitions => false}
          aasm_options.update(options)
          aasm(aasm_options, &block)
        end
      end #base.instance_eval
      
      # modifies to_xml do that it includes all the possible events from this state.
      # useful when you are using WorkItems as resources with ActiveResource
      def to_xml_with_events
        to_xml_without_events do |xml|
          xml.aasm_events_for_current_state(:type=>"array") do
            aasm_events_for_current_state.each do |e|
              xml.aasm_event do
                xml.name e.to_s
              end
            end
          end
        end
      end
      
      base.instance_eval do
        unless method_defined? :to_xml_without_events
          alias_method_chain :to_xml, :events
        end
      end
      
    end #self.included
    
  end
end
