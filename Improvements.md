1. MODIS Shurb PFT is represented by LPJ C3 grass - the realism of this should be investigated.
2. For the LUT that gets called when the MODIS and LPJ PFT's do not align, it would be good to have high-latitude and low-latitude representatives for all PFTs that get mixed with snow/soil, particularly the C3 PFT.
3. Outputting reflectance by PFT (instead of mixing and taking the average or not mixing and exporting the maximum) could be beneficial and reduce the amount the LUT is used.
    1.  This would allow the PFT-specific spectra to be pulled much more frequently that using the LUT, however the output code and ncdf R scripts would need to be modifed.
4. An alternative option would be to do a larger search for the correct PFT BEFORE using the LUT. Should try this first!
