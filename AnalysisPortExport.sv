//Author: Manish Singhal
//Date: 12 Mar15
//Description: This example demostrate the following features:
// Analysis port and export implementation and write() function

`include "uvm_macros.svh"

module test;
  
  import uvm_pkg::*;
  
/// Transaction Declaration
  class my_txn extends uvm_sequence_item;
    `uvm_object_utils(my_txn)
    
    /// Data members
    typedef enum {READ, WRITE, IDLE} kind_t;
    kind_t kind;
    rand bit [7:0] addr;
    rand byte data;
    bit write;
    
    function new(string name = "");
      super.new(name);
      kind = kind_t'($urandom_range(0,1));
    endfunction: new
  endclass: my_txn
  
  //// Typedef declarations
     typedef my_txn T; // transaction typedef
    `define my_put_port MP  // Put Port define
  	`define my_get_port MG  // Get Port Define
  
/// Producer Declaration
  class producer extends uvm_component;
    `uvm_component_utils(producer);
    
    uvm_blocking_put_port #(T) MP;
    
    function new (string name, uvm_component parent);
      super.new(name, parent);
      MP = new("MP", this);
    endfunction: new
       
    task run_phase (uvm_phase phase);
      for (int i=1; i<11; i++)
        begin
          T txn;
          txn = T::type_id::create("txn", this);
          MP.put(txn);
          `uvm_info("PID", $sformatf("Transaction no. %0d is send as %s", i, txn.kind), UVM_LOW);
          #10;
        end
    endtask: run_phase
                                     
  endclass: producer               
  
  
/// Consumer Declaration
  class consumer extends uvm_component;
    `uvm_component_utils(consumer)
    
    uvm_blocking_get_port #(T) MG; // Get Port declaration
    uvm_analysis_port #(T) aport; // Analysis Port declaration
    
    function new (string name, uvm_component parent);
      super.new(name, parent);
      MG = new("MG", this);
      aport = new("aport", this);
    endfunction: new
    
    task run_phase (uvm_phase phase);
      for(int ii=1; ii<11; ii++)
        begin
          T t;
          MG.get(t);
          `uvm_info("CID", $sformatf("Transaction no. %0d is received as %s", ii, t.kind), UVM_LOW);
          aport.write(t);
          `uvm_info("CID", $sformatf("Transaction no. %0d is sent as %s to Subscriber", ii, t.kind), UVM_LOW);
          #10;
        end
    endtask: run_phase
    
  endclass: consumer
  
  
/// Analysis Component Declaration e.g. Coverage Collector, Scoreboard
//  class cov_collector #(type TT = my_txn) extends uvm_subscriber #(TT);
  class cov_collector extends uvm_subscriber #(T);
    `uvm_component_utils(cov_collector)

    
    function new (string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new
    
    function void write (T t);
      `uvm_info("SID", $sformatf("Bingo!!!!! Transaction is received with %s", t.kind), UVM_LOW);
    endfunction: write
    
  endclass: cov_collector


/// Environment Class Declaration
  class env extends uvm_env;
    `uvm_component_utils(env);
    
    producer p1;
    consumer c1;
    uvm_tlm_fifo #(T) tlm_fifo;
    cov_collector cc1;
    
    
    function new(string name, uvm_component parent);
      super.new(name, parent);
      tlm_fifo = new("tlm_fifo", this);
    endfunction: new
    
    function void build_phase (uvm_phase phase);
      super.build_phase(phase);
      p1 = producer::type_id::create("p1", this);
      c1 = consumer::type_id::create("c1", this);
      cc1 = cov_collector::type_id::create("cc1", this);
    endfunction: build_phase
    
    function void connect_phase(uvm_phase phase);
      p1.MP.connect(tlm_fifo.put_export);
      c1.MG.connect(tlm_fifo.get_export);
      c1.aport.connect(cc1.analysis_export);
    endfunction: connect_phase
        
  endclass: env
    
  class my_test extends uvm_test;
    `uvm_component_utils(my_test);
      
	/// Environment class instantiation
  	env e;
    
    function new (string name, uvm_component parent);
      super.new(name, parent);
    endfunction: new
    
    function void build_phase (uvm_phase phase);
      super.build_phase(phase);
      e = env::type_id::create("env", this);
    endfunction: build_phase
    
    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      #1000;
      phase.drop_objection(this);
    endtask: run_phase
    
  endclass: my_test

  
/// Calling the my_test from the initial block
 initial
   begin
     run_test("my_test");
   end
  
endmodule: test
