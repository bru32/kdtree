# demo3

import tkinter as tk
import heapq

dim = 2
best = None
mindist = float("inf")

class Node:
  def __init__(self, coord):
    self.coord = coord
    self.left = None
    self.right = None

def make_tree(arr, depth=0):
  n = len(arr)
  if n == 0: return
  ax = depth % dim
  arr.sort(key=lambda p:p[ax])
  m = n // 2
  node = Node(arr[m])
  node.left = make_tree(arr[:m], depth+1)
  node.right = make_tree(arr[m+1:], depth+1)
  return node

def calc_dist(a, b):
  dist = 0
  for i in range(dim):
    dist += (a[i]-b[i])**2
  return dist

def find_all(np, cp, depth=0):
  if not np: return
  ax = depth % dim
  dist = calc_dist(np.coord, cp)
  pq.push(dist, np.coord)
  find_all(np.left, cp, depth+1)
  find_all(np.right, cp, depth+1)

def find_nn(np, cp, depth=0):
  global best, mindist
  if not np: return
  dist = calc_dist(np.coord, cp)
  if dist < mindist:
    best = np.coord
    mindist = dist
  ax = depth % dim
  target = cp[ax]
  plane = np.coord[ax]
  if target <= plane:
    find_nn(np.left, cp, depth+1)
  else:
    find_nn(np.right, cp, depth+1)
  if (target - plane)**2 <= mindist:
    if target <= plane:
      find_nn(np.right, cp, depth+1)
    else:
      find_nn(np.left, cp, depth+1)



class MainForm(tk.Frame):

  def __init__(self, parent):
    super().__init__(parent, relief="flat", highlightthickness=0)
    self.pack(fill="both", side="top", expand=1)


    self.arr = [(40, 120), (40, 320), (80, 80),
                (80, 400), (120, 240), (160, 40),
                (200, 160), (240, 320), (280, 160),
                (280, 280), (320, 80), (320, 200),
                (360, 360)]

    self.tree = make_tree(self.arr)

    # main frame to hold canvas fr2
    fr2 = tk.Frame(self)
    fr2.pack(fill="both", expand=True, side="right")

    # create a drawing surface
    self.canvas = tk.Canvas(fr2, bd=0, bg="white",
      highlightthickness=0, relief='ridge')
    self.canvas.pack(anchor="n", fill="both", side="top", expand=1)

    # events
    self.canvas.bind("<Configure>", self.paint)
    self.canvas.bind("<Motion>", self.mouse_move)


  def paint(self, ev):
    """ clear and redraw the canvas
    """
    self.canvas.delete("all")

    self.width = ev.width
    self.height = ev.height
    self.canvas.config(width=self.width, height=self.height)

    r = 5
    for a in self.arr:
      x, y = a
      coords = x-r, y-r, x+r, y+r
      self.canvas.create_oval(coords)

  def mouse_move(self, ev):
    """ mouse move over canvas """
    global mindist, best
    cp = (ev.x, ev.y)
    best = None
    mindist = float("inf")
    find_nn(self.tree, cp)
    x, y = best
    coords = cp, best
    self.canvas.delete("link")
    self.canvas.create_line(coords, width=2, fill="red", tag="link")


root = tk.Tk()
root.title("kd-tree demo")
root.geometry("400x400+860+80")
MainForm(root)
root.mainloop()
