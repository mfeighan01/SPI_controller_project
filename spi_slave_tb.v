`timescale 1ns / 1ps

module spi_slave_tb;

    // --- Signals ---
    reg clk, rst, sclk, cs, mosi;
    wire miso, done;
    wire [7:0] received_data;
    
    wire [7:0] test_bit_count;
    wire test_state;

    // --- DUT Instantiation ---
    spi_slave uut (
        .clk(clk), .rst(rst), .sclk(sclk), .cs(cs), 
        .mosi(mosi), .miso(miso), .done(done), 
        .received_data(received_data),
        
        .test_bit_count(test_bit_count),
        .test_state(test_state)
    );

    // --- System Clock Generation (100MHz) ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- Main Test Logic ---
    initial
    begin
        init();
        reset_dut();

        // Send bytes at 10 MHz
        send_byte(8'hA4, 10); 
        send_byte(8'h3C, 10);
        // Send a byte at a slower 2 MHz
        send_byte(8'hFF, 2);

        // Edge cases
        send_byte(8'h00, 5);
        send_byte(8'h80, 5);

        $display("\nAll tests finished!");
        $finish;
    end

    // --- Task: Initialise Signals ---
    task init;
        begin
            sclk = 0;
            cs   = 1;
            mosi = 0;
            rst  = 0;
        end
    endtask

    // --- Task: Reset the Slave ---
    task reset_dut;
        begin
            rst = 1;
            #20 rst = 0;
            #20; 
        end
    endtask

    // --- Task: Generate SCLK Cycle ---
    // Takes frequency in MHz and toggles the clock once
    task generate_sclk(input real freq_mhz);
        real period_ns;
        begin
            period_ns = 1000.0 / freq_mhz; // Convert MHz to Period in ns
            #(period_ns / 2.0) sclk = 1;   // High for half period
            #(period_ns / 2.0) sclk = 0;   // Low for half period
        end
    endtask

    // --- Task: Master Send ---
    task send_byte(input [7:0] data, input real freq_mhz);
        integer i;
        begin
            $display("[SENDING] %h at %0f MHz", data, freq_mhz);
            @(posedge clk);
            cs <= 0; 
            
            for (i = 7; i >= 0; i = i - 1)
            begin
                mosi <= data[i];
                generate_sclk(freq_mhz); // Call the new clock generator
            end
        end
    endtask

endmodule
