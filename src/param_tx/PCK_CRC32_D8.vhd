-----------------------------------------------------------------------
-- File:  PCK_CRC32_D8.vhd                              
-- Date:  Thu Nov 27 13:05:21 2008                                                      
--                                                                     
-- Copyright (C) 1999-2003 Easics NV.                 
-- This source file may be used and distributed without restriction    
-- provided that this copyright statement is not removed from the file 
-- and that any derivative work contains the original copyright notice
-- and the associated disclaimer.
--
-- THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
-- OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
-- WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
--
-- Purpose: VHDL package containing a synthesizable CRC function
--   * polynomial: (0 1 2 4 5 7 8 10 11 12 16 22 23 26 32)
--   * data width: 8
--                                                                     
-- Info: tools@easics.be
--       http://www.easics.com                                  
-----------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;

package PCK_CRC32_D8 is

  -- polynomial: (0 1 2 4 5 7 8 10 11 12 16 22 23 26 32)
  -- data width: 8
  -- convention: the first serial data bit is D(7)
  function nextCRC32_D8
    ( Data:  std_logic_vector(7 downto 0);
      CRC:   std_logic_vector(31 downto 0))
    return std_logic_vector;

end PCK_CRC32_D8;

library IEEE;
use IEEE.std_logic_1164.all;

package body PCK_CRC32_D8 is

  -- polynomial: (0 1 2 4 5 7 8 10 11 12 16 22 23 26 32)
  -- data width: 8
  -- convention: the first serial data bit is D(7)
  function nextCRC32_D8  
    ( Data:  std_logic_vector(7 downto 0);
      CRC:   std_logic_vector(31 downto 0) )
    return std_logic_vector is

    variable D: std_logic_vector(7 downto 0);
    variable C: std_logic_vector(31 downto 0);
    variable NewCRC: std_logic_vector(31 downto 0);

  begin

    D := Data;
    C := CRC;

NewCRC(0)  := c(30) xor d(7) xor c(24) xor d(1);
NewCRC(1)  := c(30) xor c(31) xor d(6) xor d(7) xor c(24) xor d(0) xor c(25) xor d(1);
NewCRC(2)  := c(30) xor c(31) xor d(5) xor d(6) xor d(7) xor c(24) xor c(25) xor c(26) xor d(0) xor d(1);
NewCRC(3)  := d(4) xor c(31) xor d(5) xor d(6) xor c(25) xor c(26) xor c(27) xor d(0);
NewCRC(4)  := c(30) xor d(4) xor d(5) xor d(7) xor c(24) xor c(26) xor c(27) xor c(28) xor d(1) xor d(3);
NewCRC(5)  := c(30) xor d(4) xor c(31) xor d(6) xor d(7) xor c(24) xor c(25) xor c(27) xor c(28) xor c(29) xor d(0) xor d(1) xor d(2) xor d(3);
NewCRC(6)  := c(30) xor c(31) xor d(5) xor d(6) xor c(25) xor c(26) xor c(28) xor c(29) xor d(0) xor d(1) xor d(2) xor d(3);
NewCRC(7)  := d(4) xor d(5) xor c(31) xor d(7) xor c(24) xor c(26) xor c(27) xor c(29) xor d(0) xor d(2);
NewCRC(8)  := d(4) xor d(6) xor d(7) xor c(24) xor c(25) xor c(27) xor c(28) xor c(0) xor d(3);
NewCRC(9)  := d(5) xor d(6) xor c(25) xor c(26) xor c(28) xor c(29) xor d(2) xor c(1) xor d(3);
NewCRC(10) := d(4) xor d(5) xor d(7) xor c(24) xor c(26) xor c(27) xor c(29) xor d(2) xor c(2);
NewCRC(11) := d(4) xor c(3) xor d(6) xor d(7) xor c(24) xor c(25) xor c(27) xor c(28) xor d(3);
NewCRC(12) := c(30) xor d(5) xor c(4) xor d(6) xor d(7) xor c(24) xor c(25) xor c(26) xor c(28) xor c(29) xor d(1) xor d(2) xor d(3);
NewCRC(13) := d(4) xor c(30) xor c(31) xor d(5) xor d(6) xor c(5) xor c(25) xor c(26) xor c(27) xor c(29) xor d(0) xor d(1) xor d(2);
NewCRC(14) := d(4) xor c(30) xor d(5) xor c(31) xor c(6) xor c(26) xor c(27) xor c(28) xor d(0) xor d(1) xor d(3);
NewCRC(15) := d(4) xor c(31) xor c(7) xor c(27) xor c(28) xor c(29) xor d(0) xor d(2) xor d(3);
NewCRC(16) := d(7) xor c(24) xor c(8) xor c(28) xor c(29) xor d(2) xor d(3);
NewCRC(17) := c(30) xor d(6) xor c(25) xor c(9) xor c(29) xor d(1) xor d(2);
NewCRC(18) := c(30) xor d(5) xor c(31) xor c(26) xor d(0) xor d(1) xor c(10);
NewCRC(19) := d(4) xor c(31) xor c(27) xor d(0) xor c(11);
NewCRC(20) := c(12) xor c(28) xor d(3);
NewCRC(21) := c(13) xor c(29) xor d(2);
NewCRC(22) := c(14) xor d(7) xor c(24);
NewCRC(23) := c(30) xor d(6) xor d(7) xor c(24) xor c(15) xor c(25) xor d(1);
NewCRC(24) := c(31) xor d(5) xor d(6) xor c(25) xor c(16) xor c(26) xor d(0);
NewCRC(25) := d(4) xor d(5) xor c(26) xor c(17) xor c(27);
NewCRC(26) := c(30) xor d(4) xor d(7) xor c(24) xor c(27) xor c(18) xor c(28) xor d(1) xor d(3);
NewCRC(27) := c(31) xor d(6) xor c(25) xor c(28) xor c(19) xor c(29) xor d(0) xor d(2) xor d(3);
NewCRC(28) := c(30) xor d(5) xor c(26) xor c(29) xor d(1) xor d(2) xor c(20);
NewCRC(29) := d(4) xor c(30) xor c(21) xor c(31) xor c(27) xor d(0) xor d(1);
NewCRC(30) := c(31) xor c(22) xor c(28) xor d(0) xor d(3);
NewCRC(31) := c(23) xor c(29) xor d(2);

    return NewCRC;

  end nextCRC32_D8;

end PCK_CRC32_D8;

