/*
 * Copyright 2018 Aurryon SCHWARTZ (Nicolas SCHWARTZ)
 * All Rights Reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */
 
/*
 * Linux radeon module 4.14 /driver/gpu/drm/radeon/radeon_acpi.h
 * Copyright 2012 Advanced Micro Devices, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER(S) OR AUTHOR(S) BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 */

DefinitionBlock ("RADC", "SSDT", 1, "AMD", "Radeon ", 0x00003000)
{
    External (_SB_.PCI0.PEG0.PEGP.SGON, MethodObj)
    External (_SB_.PCI0.PEG0.PEGP.SGOF, MethodObj)
    External (_SB_.PCI0.GFX0, DeviceObj)

    Scope (\_SB.PCI0.GFX0)
    {
        Name(SROM, VGA Bios size here)
        Name (CROM, Buffer (VGA Bios size here)
        {
            //VGA Bios Content here
        })

       /* ATRM
        * ARG0: (ACPI_INTEGER) offset of vbios rom data
        * ARG1: (ACPI_BUFFER) size of the buffer to fill (up to 4K).
        * OUTPUT: (ACPI_BUFFER) output buffer
        * ATRM provides an interfacess to access the discrete GPU vbios image on
        * PowerXpress systems with multiple GPUs.
        */
        
        Method (ATRM, 2, Serialized)
        {
            If (AND (LLessEqual (Zero, Arg0), LLess (Arg0, SROM)))
            {
                Add (Arg0, Arg1, Local0)
                Multiply (Arg0, 0x08, Local1)
                If (LLessEqual (Local0, SROM)) //We take a portion inside CROM
                {
                    Store(Arg1, Local3)
                    Multiply (Arg1, 0x08, Local2)
                }
                Else //Arg0 + Arg1 is outside the CROM
                {
                    Subtract (SROM, Arg0, Local3)
                    Multiply (Local3, 0x08, Local2)
                    
                }
                CreateField (CROM, Local1, Local2, TEMP)
                Name (RETA, Buffer (Local3) {})
                Store (TEMP, RETA)
                Return (RETA)
            }
            Else
            {
                Name (RETB, Buffer (One) {})
                Return (RETB)
            }
        }
        
       /* ATPX
        * ARG0: (ACPI_INTEGER) function code
        * ARG1: (ACPI_BUFFER) parameter buffer, 256 bytes
        * OUTPUT: (ACPI_BUFFER) output buffer, 256 bytes
        * ATPX methods are used on PowerXpress systems to handle mux switching and
        * discrete GPU power control.
        */
        
        Method (ATPX, 2, Serialized)
        {
           /* ATPX 
            * ATPX_FUNCTION_VERIFY_INTERFACE                             0x0
            * ARG0: ATPX_FUNCTION_VERIFY_INTERFACE
            * ARG1: none
            * OUTPUT:
            * WORD  - structure size in bytes (includes size field)
            * WORD  - version
            * DWORD - supported functions bit vector
            *
            * supported functions vector
            * ATPX_GET_PX_PARAMETERS_SUPPORTED                    (1 << 0)
            * ATPX_POWER_CONTROL_SUPPORTED                        (1 << 1)
            * ATPX_DISPLAY_MUX_CONTROL_SUPPORTED                  (1 << 2)
            * ATPX_I2C_MUX_CONTROL_SUPPORTED                      (1 << 3)
            * ATPX_GRAPHICS_DEVICE_SWITCH_START_NOTIFICATION_SUPPORTED (1 << 4)
            * ATPX_GRAPHICS_DEVICE_SWITCH_END_NOTIFICATION_SUPPORTED   (1 << 5)
            * ATPX_GET_DISPLAY_CONNECTORS_MAPPING_SUPPORTED       (1 << 7)
            * ATPX_GET_DISPLAY_DETECTION_PORTS_SUPPORTED          (1 << 8)
            */
            
            If (LEqual (Arg0, Zero))
            {
                Name (TMP1, Buffer (0x0100)
                {
                     0x00
                })
                CreateWordField (TMP1, Zero, F0MS)
                CreateWordField (TMP1, 0x02, F0VM)
                CreateDWordField (TMP1, 0x04, F0SF)
                Store (0x0008, F0MS)
                Store (0x0001, F0VM)
                Store (0x00000003, F0SF) //We only support ATPX_POWER_CONTROL_SUPPORTED 
                Return (TMP1)
            }
            
           /* ATPX_FUNCTION_GET_PX_PARAMETERS                            0x1
            * ARG0: ATPX_FUNCTION_GET_PX_PARAMETERS
            * ARG1: none
            * OUTPUT:
            * WORD  - structure size in bytes (includes size field)
            * DWORD - valid flags mask
            * DWORD - flags
            *
            * flags 
            * ATPX_LVDS_I2C_AVAILABLE_TO_BOTH_GPUS                (1 << 0)
            * ATPX_CRT1_I2C_AVAILABLE_TO_BOTH_GPUS                (1 << 1)
            * ATPX_DVI1_I2C_AVAILABLE_TO_BOTH_GPUS                (1 << 2)
            * ATPX_CRT1_RGB_SIGNAL_MUXED                          (1 << 3)
            * ATPX_TV_SIGNAL_MUXED                                (1 << 4)
            * ATPX_DFP_SIGNAL_MUXED                               (1 << 5)
            * ATPX_SEPARATE_MUX_FOR_I2C                           (1 << 6)
            * ATPX_DYNAMIC_PX_SUPPORTED                           (1 << 7)
            * ATPX_ACF_NOT_SUPPORTED                              (1 << 8)
            * ATPX_FIXED_NOT_SUPPORTED                            (1 << 9)
            * ATPX_DYNAMIC_DGPU_POWER_OFF_SUPPORTED               (1 << 10)
            * ATPX_DGPU_REQ_POWER_FOR_DISPLAYS                    (1 << 11)
            * ATPX_DGPU_CAN_DRIVE_DISPLAYS                        (1 << 12)
            * ATPX_MS_HYBRID_GFX_SUPPORTED                        (1 << 14)
            */
            
            If (LEqual (Arg0, One))
            {
                Name (TMP2, Buffer (0x0100)
                {
                     0x00
                })
                CreateWordField (TMP2, Zero, F1MS)
                CreateDWordField (TMP2, 0x02, F1FM)
                CreateDWordField (TMP2, 0x06, F1FS)
                Store (0x000A, F1MS)
                Store (0x00001C80, F1FM) //Refer to flag description
                Store (0x00001C80, F1FS) //Same as F1FM
                Return (TMP2)
            }

            /* ATPX_FUNCTION_POWER_CONTROL                                0x2 */
            
            If (LEqual (Arg0, 0x02))
            {
                CreateByteField (Arg1, 0x02, DGPR)
                And (DGPR, One, DGPR)
                Sleep (0x03E8)
                If (LEqual (DGPR, Zero))
                {
                    \_SB.PCI0.PEG0.PEGP.SGOF()
                }

                If (LEqual (DGPR, One))
                {
                    \_SB.PCI0.PEG0.PEGP.SGON()
                }
                Sleep (0x03E8)
            }
            Return (Zero)
        }
    }
}
