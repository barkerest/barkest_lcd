module BarkestLcd
  module SimpleDebug

    def self.included(base)
      base.class_eval do

        protected

        ##
        # Gets the debug message handler for the model.
        def self.on_debug_callback
          @on_debug ||= Proc.new do
            nil
          end
        end

        public

        ##
        # Sets a debug message handler for the model.
        #
        # Yields the debug message.
        def self.on_debug(&block)
          raise ArgumentError, 'Missing block.' unless block_given?
          @on_debug = block
          self
        end
      end
    end

    public

    ##
    # Handles a debug message.
    def debug(msg)
      self.class.on_debug_callback.call(msg)
    end

    ##
    # Contains the last 100 errors that have occurred in this instance.
    def error_history
      @error_history ||= []
    end

    protected

    def log_error(code, msg)
      debug "Encountered error (#{code.to_s(16).rjust(8, '0')}) #{msg}"
      error_history << [ code, msg, Time.now ]
      error_history.delete_at(0) while error_history.count > 100
    end

  end
end
