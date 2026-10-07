# Screenshot two: plate cutout

Final export: `../en-US/02-meal-breakdown.png` — 1290 × 2796, opaque sRGB.

The final uses a traced clipping path around the original photographed plate, positioned beyond the right edge with a soft shadow. The breakdown is a continuous crop from the revised 6:38:12 PM capture. Headline uses the native system SF Pro semibold face. No app text or nutrition values are regenerated.

A built-in image-generation background extraction was explored, but its food rendering changed the source appearance, so it was not used in the final. No CLI/API fallback was used.

## Exploratory prompt

Use case: background-extraction. Input image is an actual iPhone screenshot containing a food photograph. Extract ONLY the original entire oval ceramic plate of rice, chopped chicken, potato wedges, salad, creamy sauce, parsley and lemon from that photograph as a clean transparent-background cutout. Remove the mosaic table, blurred letterboxing and ALL app UI/text. Preserve the food's actual appearance, arrangement, color, angle, and the full blue-edged plate rim. Do not redesign, restyle, add ingredients, change the food, add text, or invent a different meal. Crop the canvas tightly around the full plate, with a small transparent margin; no drop shadow, no white background, no checkerboard. Output only the isolated original plate on real transparency. Landscape aspect matching the photographed plate.
