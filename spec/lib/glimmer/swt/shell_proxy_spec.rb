require "spec_helper"

module GlimmerSpec
  describe Glimmer::SWT::ShellProxy do
    include Glimmer

    it "sets data('proxy')" do
      @target = shell {
      }
      
      expect(@target.get_data('proxy')).to eq(@target)
    end
    
    unless OS.windows?
      describe '#visible?' do
        it 'returns false before initially opened and true afterwards' do
          @target = described_class.new
          @target.setAlpha(0) # keep invisible while running specs
          expect(@target.visible?).to eq(false)
          @target.async_exec do
            expect(@target.visible?).to eq(true)
            @target.close
            expect(@target.visible?).to eq(false)
          end
          @target.open
        end
  
        it 'returns false if hidden after initially opened (this time with alias method show)' do
          @target = described_class.new
          @target.setAlpha(0) # keep invisible while running specs
          @target.async_exec do
            expect(@target.visible?).to eq(true)
            @target.hide
            expect(@target.visible?).to eq(false)
            @target.close
          end
          @target.show
        end
  
        it 'returns false when visibility is set to false in described_class' do
          @target = described_class.new
          @target.setAlpha(0) # keep invisible while running specs
          @target.async_exec do
            expect(@target.visible?).to eq(true)
            @target.visible = false
            expect(@target.visible?).to eq(false)
            expect(@target.isVisible).to eq(false)
            @target.close
          end
          @target.visible = true
        end
      end
  
      describe '#pack' do
        it 'packs shell content by invoking SWT Shell#pack' do
          @target = shell {
            alpha 0 # keep invisible while running specs
            grid_layout 1, false
            @text = text {
              layout_data :fill, :fill, true, true
              text 'A'
            }
          }
  
          text_width = @text.getSize.x
          shell_width = @target.getSize.x
  
          @text.setText('A very long text it cannot fit in the screen if you keep reading on' + ' and on'*60)
          @target.pack # packing shell should resize text widget
   
          expect(@text.getSize.x > text_width).to eq(true)
          expect(@target.getSize.x > shell_width).to eq(true)
        end
      end
  
      describe '#pack_same_size' do
        it 'packs shell content while maintaining the same shell size (widget sizes may vary)' do
          @target = shell {
            alpha 0 # keep invisible while running specs
            grid_layout 1, false
            @text = text {
              layout_data :fill, :fill, true, true
              text 'A'
            }
          }
   
          text_width = @text.getSize.x
          shell_width = @target.getSize.x
   
          @text.setText('A very long text it cannot fit in the screen if you keep reading on' + ' and on'*60)
          @target.pack_same_size # packing shell should resize text widget but keep same shell size
   
          expect(@text.getSize.x > text_width).to eq(true)
          expect(@target.getSize.x).to eq(shell_width)
        end
      end
  
      describe 'visibility observation' do
        it 'notifies when becoming visible' do
          @shown = false
          @target = described_class.new
          @target.setAlpha(0) # keep invisible while running specs
          @target.on_swt_show {
            @shown = true
          }
          @target.async_exec do
            expect(@target.visible?).to eq(true)
            expect(@shown).to eq(true)
            @target.close
          end
          expect(@target.visible?).to eq(false)
          expect(@shown).to eq(false)
          @target.show
        end
  
        it 'notifies when becoming non-visible (observed with alternative syntax)' do
          @target = described_class.new
          @target.setAlpha(0) # keep invisible while running specs
          @target.on_swt_hide {
            expect(@target.visible?).to eq(false)
            @target.close
          }
          @target.async_exec do
            @target.hide
          end
          @target.show
        end
      end
    end
    
  end
end        
