# kdtree
Kd-tree example

The existing code by Victor finds only 1 nearest neighbour.  The problem is that if you search from an existing node, then it finds the nearest neighbour to be itself!  But, I want the node that is nearest to the existing node.

kd.dpr is a command line version

kd2 is a Delphi Form app.
It draws lines from the mouse position to the 3 nearest nodes.
As a test, I added a brute force search.

WARNING ...
My FindKNearest has a tiny bug.  The 3rd coord is not always the right one.  I'm not sure why!!!  Let me know if you can find the reason.  

