module Glimmer
  module SWT
    # Proxy for org.eclipse.swt.graphics.Image
    #
    # Invoking `#swt_image` returns the SWT Image object wrapped by this proxy
    #
    # Follows the Proxy Design Pattern
    class ImageProxy
      include_package 'org.eclipse.swt.graphics'
      
      attr_reader :file_path, :jar_file_path, :image_data, :swt_image

      # Initializes a proxy for an SWT Image object
      #
      # Takes the same args as the SWT Image class
      # Alternatively, takes a file path string or a uri:classloader file path string (generated by JRuby when invoking `File.expand_path` inside a JAR file)
      # and returns an image object.
      def initialize(*args)
        @args = args
        @file_path = @args.first if @args.first.is_a?(String) && @args.size == 1        
        if @file_path
          if @file_path.start_with?('uri:classloader')
            @jar_file_path = @file_path
            @file_path = @jar_file_path.sub(/^uri\:classloader\:/, '').sub('//', '/') # the latter sub is needed for Mac
            object = java.lang.Object.new
            file_input_stream = object.java_class.resource_as_stream(file_path)
            buffered_file_input_stream = java.io.BufferedInputStream.new(file_input_stream)
          end
          @image_data = ImageData.new(buffered_file_input_stream || @file_path)
          @swt_image = Image.new(DisplayProxy.instance.swt_display, @image_data)
        else
          @swt_image = Image.new(*@args)
          @image_data = @swt_image.image_data
        end        
      end

      def scale_to(width, height)
        scaled_image_data = image_data.scaledTo(width, height)
        device = swt_image.device
        swt_image.dispose
        @swt_image = Image.new(device, scaled_image_data)
      end
      
      def method_missing(method, *args, &block)
        swt_image.send(method, *args, &block)
      rescue => e
        Glimmer::Config.logger.debug {"Neither ImageProxy nor #{swt_image.class.name} can handle the method ##{method}"}
        super
      end
      
      def respond_to?(method, *args, &block)
        super || swt_image.respond_to?(method, *args, &block)
      end      
    end
  end
end
