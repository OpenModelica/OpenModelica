// name: Comment2
// keywords: comment
// status: correct
//
// This file tests /* */-style comments
//

/* Comment
 * That
 * Spans
 * Over
 * Multiple
 * Lines






 */
model Comment2 /* Another Comment */
  Real x;
  /* Commenting
     Again */
equation /* Comment */
  x = 2;
end Comment2; /* Comment
*/
/* Comment */

// Result:
// class Comment2
//   Real x;
// equation
//   x = 2.0;
// end Comment2;
// endResult
