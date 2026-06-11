package test_pkg;

  `include "uvm_macros.svh"
  import uvm_pkg::*;
  import axi_lite_pkg::*;
  import ahb_pkg::*;
  import bridge_pkg::*;
  //todo reset pkg

  // `include "ready_valid_virtual_seq_lib.svh"
  `include "bridge_virtual_seq.svh"
  `include "bridge_test.svh"
endpackage
