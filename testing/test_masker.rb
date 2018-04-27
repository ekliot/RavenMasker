require_relative '../masker'

img = 'testing/test_small.png'
img_masked = 'testing/test_small_masked.png'
msg = "do you want to live forever?"
tags = [ 'valeria', 'arnold', 'crom' ]

p Masker.mask img, msg, tags
p Masker.unmask img_masked, tags
