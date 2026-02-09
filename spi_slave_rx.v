module spi_slave
(
// SPI Mode 0 Receiver
// CPOL = 0
// CPHA = 0
// Samples mosi on rising edge of sclk

    // System
    input  wire clk,  // System clock
    input  wire rst,  // Async reset active HIGH

    // SPI Signals
    input  wire sclk,  // SPI clock 
    input  wire cs,  // Chip select active LOW
    input  wire mosi,  // Master Out Slave In data line

    output wire miso,  // Master In Slave Out data line
    
    // Data outputs
    output reg  done,  // Pulses HIGH when one byte received
    output reg [7:0] received_data,  // Captured byte
    
    // Debug outputs
    output [7:0] test_bit_count,  // External observation of bit_count
    output reg test_state  // External observation of state
);

//---------- Edge Detection Logic --------------
    wire sclk_rising;  // rising edge of sclk
    wire sclk_falling;  // falling edge of sclk
    
    // Shift registers capturing sclk, cs, mosi samples
    reg [1:0] sclk_sync;  
    reg [1:0] cs_sync;  
    reg [1:0] mosi_sync;
    
    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
        
            // Initalise synchronisers on reset
            sclk_sync <= 2'b00;
            cs_sync <= 2'b11;  // Forces idle state
            mosi_sync <= 2'b00;
        end
        else begin
        
        // Shift new async samples into synchronisers
        sclk_sync <= {sclk_sync[0], sclk};
        cs_sync   <= {cs_sync[0], cs};
        mosi_sync <= {mosi_sync[0], mosi};
        end
    end
    
    // Final stage of synchroniser as usable stable signal
    wire sclk_s = sclk_sync[1];
    wire cs_s   = cs_sync[1];
    wire mosi_s = mosi_sync[1];
    
    // Edge detection through comparison of successive samples
    assign sclk_rising  = (sclk_sync[1] & ~sclk_sync[0]);
    assign sclk_falling = (~sclk_sync[1] & sclk_sync[0]);

//---------- FSM Logic --------------

    // State encoding
    localparam IDLE      = 1'b0;  // Slave deselected
    localparam RECEIVING = 1'b1;  // Slave selected and shifting data
    
        reg state;  // Current state
        reg next_state;  // Next state
         
    // Sequential state register
    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin  
            state <= IDLE;  // Reset forces idle condition
        end else 
        begin
            state <= next_state;  // State updates each clk cycle
        end
    end

    // Combinational Block: Next State Logic 
    always @(*)
    begin
        next_state = state; // Default assignment prevents latching
        
        case (state)
        
            // When idle, check if CS goes LOW
            IDLE:
            begin
                if (!cs_s)  
                next_state = RECEIVING; 
            end
            
            // While receiving, return to idle if CS goes HIGH
            RECEIVING:
            begin
                if (cs_s) next_state = IDLE;
            end
            
            // Default to idle
            default:    next_state = IDLE;
        endcase
    end
    
//---------- Datapath Logic: Shift Register & Bit Counter --------------

    assign miso = 1'bz;   // TX not implemented yet
    
    reg [7:0] bit_count;  // 8-bit one-hot ring counter indicates which bit is being shifted
    reg [7:0] shift_reg;  // Register holding incoming serial data
    wire byte_complete;  // Flag asserted when MSB of ring counter HIGH
    // Combinational next value of shift_reg so the shifted byte
    // can be latched correctly within the same clock cycle
    wire [7:0] next_shift;  
    
    assign next_shift = {shift_reg[6:0], mosi_s};
    assign byte_complete = bit_count[7];  // When MSB HIGH, one byte has been shifted
    
    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            // Initalise counter and registers
            bit_count <= 8'b0000_0001;  
            shift_reg <= 8'b0;
            
            received_data <= 8'b0;
            done <= 0;
        end else
        begin
            // done pulse is cleared each cycle
            done <=0;
            
            // If slave deselected, reset counter
            if (state == IDLE)
            begin
                bit_count <= 8'b0000_0001;
            end 
            
            // Sample MOSI on rising sclk edge (SPI mode 0)
            else if (state == RECEIVING && sclk_rising)
            begin
                // Shift new bit into register
                shift_reg <= next_shift;
                
                // When register is loaded
                if (byte_complete)
                begin
                    done <= 1'b1;  // Pulse completion flag
                    received_data <= next_shift;  // Latch byte
                    bit_count <= 8'b0000_0001;  // Restart counter for next byte
                end else
                begin
                bit_count <= {bit_count[6:0], 1'b0};  // Increment ring counter
                end
            end
         end
     end
// ------------ Debug outputs ------------

    // Probe ring counter
    assign test_bit_count = bit_count;
    
    // Probe state encoding
    always @(*)
    begin
        case (state)  
            IDLE:      test_state = 1'b0;  
            RECEIVING: test_state = 1'b1;  
            default:   test_state = 1'b0; 
        endcase
    end
endmodule
