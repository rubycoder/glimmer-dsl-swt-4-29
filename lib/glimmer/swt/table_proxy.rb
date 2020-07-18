require 'glimmer/swt/widget_proxy'

module Glimmer
  module SWT
    class TableProxy < Glimmer::SWT::WidgetProxy
      include Glimmer
      
      module TableListenerEvent        
        def table_item
          table_item_and_column_index[:table_item]
        end
        
        def column_index
          table_item_and_column_index[:column_index]
        end     
        
        private
        
        def table_item_and_column_index
          @table_item_and_column_index ||= find_table_item_and_column_index
        end
        
        def find_table_item_and_column_index
          {}.tap do |result|
            if respond_to?(:x) && respond_to?(:y)
              result[:table_item] = widget.items.detect do |ti|
                result[:column_index] = widget.column_count.times.to_a.detect do |ci|
                  ti.getBounds(ci).contains(x, y)
                end
              end
            end
          end
        end   
      end
      
      class << self
        def editors
          @editors ||= {
            text: lambda do |args, model, property, table_proxy|
              table_editor_widget_proxy = text(*args) {
                text model.send(property)
                focus true
                on_focus_lost {
                  table_proxy.finish_edit!(:text)
                }
                on_key_pressed { |key_event|
                  if key_event.keyCode == swt(:cr)
                    table_proxy.finish_edit!(:text)
                  elsif key_event.keyCode == swt(:esc)
                    table_proxy.cancel_edit!
                  end
                }              
              }
              table_editor_widget_proxy.swt_widget.selectAll          
              table_editor_widget_proxy
            end,
            combo: lambda do |args, model, property, table_proxy|
              table_editor_widget_proxy = combo(*args) {
                items model.send("#{property}_options")
                text model.send(property)
                focus true
                on_focus_lost {
                  table_proxy.finish_edit!(:text)
                }
                on_key_pressed { |key_event|
                  if key_event.keyCode == swt(:cr)
                    table_proxy.finish_edit!(:text)
                  elsif key_event.keyCode == swt(:esc)
                    table_proxy.cancel_edit!
                  end
                }
                on_widget_selected {
                  table_proxy.finish_edit!(:text)
                }
              }
              table_editor_widget_proxy
            end,
          }      
        end
      end
      
      attr_reader :table_editor, :table_editor_text_proxy, :table_editor_widget_proxy, :sort_property, :sort_direction, :sort_block, :sort_type, :sort_by_block, :additional_sort_properties, :editor
      attr_accessor :column_properties
      
      def initialize(underscored_widget_name, parent, args)
        super
        @table_editor = TableEditor.new(swt_widget)
        @table_editor.horizontalAlignment = SWTProxy[:left]
        @table_editor.grabHorizontal = true
        @table_editor.minimumHeight = 20
      end

      def model_binding
        swt_widget.data
      end      
      
      def sort_by_column(table_column_proxy)
        index = swt_widget.columns.to_a.index(table_column_proxy.swt_widget)
        new_sort_property = table_column_proxy.sort_property || [column_properties[index]]
        if new_sort_property.size == 1 && !additional_sort_properties.to_a.empty?
          selected_additional_sort_properties = additional_sort_properties.clone
          if selected_additional_sort_properties.include?(new_sort_property.first)
            selected_additional_sort_properties.delete(new_sort_property.first)
            new_sort_property += selected_additional_sort_properties
          else
            new_sort_property += additional_sort_properties
          end
        end
        
        @sort_direction = @sort_direction.nil? || @sort_property != new_sort_property || @sort_direction == :descending ? :ascending : :descending        
        swt_widget.sort_direction = @sort_direction == :ascending ? SWTProxy[:up] : SWTProxy[:down]
        
        @sort_property = new_sort_property
        swt_widget.sort_column = table_column_proxy.swt_widget
        
        @sort_by_block = nil
        @sort_block = nil
        @sort_type = nil
        if table_column_proxy.sort_by_block
          @sort_by_block = table_column_proxy.sort_by_block
        elsif table_column_proxy.sort_block
          @sort_block = table_column_proxy.sort_block
        else
          detect_sort_type        
        end
        sort
      end
      
      def detect_sort_type
        @sort_type = sort_property.size.times.map { String }
        array = model_binding.evaluate_property
        sort_property.each_with_index do |a_sort_property, i|
          values = array.map { |object| object.send(a_sort_property) }
          value_classes = values.map(&:class).uniq
          if value_classes.size == 1
            @sort_type[i] = value_classes.first
          elsif value_classes.include?(Integer)
            @sort_type[i] = Integer
          elsif value_classes.include?(Float)
            @sort_type[i] = Float
          end
        end
      end
      
      def additional_sort_properties=(args)
        @additional_sort_properties = args unless args.empty?
      end
      
      def editor=(args)
        @editor = args
      end 
      
      def sort
        return unless sort_property && (sort_type || sort_block || sort_by_block)
        array = model_binding.evaluate_property
        # Converting value to_s first to handle nil cases. Should work with numeric, boolean, and date fields
        if sort_block
          sorted_array = array.sort(&sort_block)
        elsif sort_by_block
          sorted_array = array.sort_by(&sort_by_block)          
        else
          sorted_array = array.sort_by do |object|
            sort_property.each_with_index.map do |a_sort_property, i|
              value = object.send(a_sort_property)
              # handle nil and difficult to compare types gracefully
              if sort_type[i] == Integer
                value = value.to_i
              elsif sort_type[i] == Float
                value = value.to_f
              elsif sort_type[i] == String
                value = value.to_s
              end
              value
            end
          end
        end
        sorted_array = sorted_array.reverse if sort_direction == :descending
        model_binding.call(sorted_array)
      end
      
      # Performs a search for table items matching block condition
      # If no condition block is passed, returns all table items
      # Returns a Java TableItem array to easily set as selection on org.eclipse.swt.Table if needed
      def search(&condition)
        swt_widget.getItems.select {|item| condition.nil? || condition.call(item)}.to_java(TableItem)
      end
      
      # Returns all table items including descendants
      def all_table_items
        search
      end

      def widget_property_listener_installers
        super.merge({
          Java::OrgEclipseSwtWidgets::Table => {
            selection: lambda do |observer|
              on_widget_selected { |selection_event|
                observer.call(@swt_widget.getSelection)
              }
            end
          },        
        })
      end
      
      def post_initialize_child(table_column_proxy)
        table_column_proxies << table_column_proxy
      end
      
      def table_column_proxies
        @table_column_proxies ||= []
      end
      
      # Indicates if table is in edit mode, thus displaying a text widget for a table item cell
      def edit_mode?
        !!@edit_mode
      end
      
      def cancel_edit!
        @cancel_edit&.call if @edit_mode
      end

      def finish_edit!(value = nil)
        @finish_edit&.call(value) if @edit_mode
      end

      # Indicates if table is editing a table item because the user hit ENTER or focused out after making a change in edit mode to a table item cell.
      # It is set to false once change is saved to model
      def edit_in_progress?
        !!@edit_in_progress
      end
      
      def edit_selected_table_item(column_index, before_write: nil, after_write: nil, after_cancel: nil)
        edit_table_item(swt_widget.getSelection.first, column_index, before_write: before_write, after_write: after_write, after_cancel: after_cancel)
      end
            
      def edit_table_item(table_item, column_index, before_write: nil, after_write: nil, after_cancel: nil)
        return if table_item.nil?
        model = table_item.data
        property = column_properties[column_index]
        @cancel_edit&.call if @edit_mode
        action_taken = false
        @edit_mode = true
        @cancel_edit = lambda do
          @cancel_in_progress = true
          @table_editor_widget_proxy&.swt_widget&.dispose
          @table_editor_widget_proxy = nil
          after_cancel&.call
          @edit_in_progress = false
          @cancel_in_progress = false
          @cancel_edit = nil
          @edit_mode = false
        end
        @finish_edit = lambda do |widget_value_property=nil|
          new_text = widget_value_property.is_a?(Symbol) ? @table_editor_widget_proxy&.swt_widget&.send(widget_value_property) : widget_value_property
          if table_item.isDisposed
            @cancel_edit.call
          elsif new_text && !action_taken && !@edit_in_progress && !@cancel_in_progress
            action_taken = true
            @edit_in_progress = true
            if new_text == model.send(property)
              @cancel_edit.call
            else
              before_write&.call
              table_item.setText(column_index, new_text)
              model.send("#{property}=", new_text) # makes table update itself, so must search for selected table item again
              edited_table_item = search { |ti| ti.getData == model }.first
              swt_widget.showItem(edited_table_item)
              @table_editor_widget_proxy&.swt_widget&.dispose
              @table_editor_widget_proxy = nil
              after_write&.call(edited_table_item)              
              @edit_in_progress = false
            end
          end
        end

        editor_config = table_column_proxies[column_index].editor || editor
        editor_widget = editor_config.to_a[0] || :text
        editor_widget_args = editor_config.to_a[1] || []
        content { 
          @table_editor_widget_proxy = @table_editor_text_proxy = TableProxy::editors[editor_widget].call(editor_widget_args, model, property, self)
        }
        @table_editor.setEditor(@table_editor_widget_proxy.swt_widget, table_item, column_index)
      end
      
      def add_listener(underscored_listener_name, &block)
        enhanced_block = lambda do |event|
          event.extend(TableListenerEvent)
          block.call(event)
        end
        super(underscored_listener_name, &enhanced_block)
      end
            
      private

      def property_type_converters
        super.merge({
          selection: lambda do |value|
            if value.is_a?(Array)
              search {|ti| value.include?(ti.getData) }
            else
              search {|ti| ti.getData == value}
            end
          end,
        })
      end
    end
  end
end
