import pylib
import std/strutils
type Customer = ref object
  name: string
  balance: float

class Customer(object):
  """A customer of ABC Bank with a checking account. Customers have the
  following properties:

  Attributes:
      name: A string representing the customer's name.
      balance: A float tracking the current balance of the customer's account.
  """

  def init(self, name, balance=0.0):
      """Return a Customer object whose name is *name* and starting
      balance is *balance*."""
      self.name = name
      self.balance = balance

  def withdraw(self, amount):
      """Return the balance remaining after withdrawing *amount*
      dollars."""
      if amount > self.balance:
          raise newException(ValueError, "Amount greater than available balance.")
      self.balance -= amount
      return self.balance

  def deposit(self, amount):
      """Return the balance remaining after depositing *amount*
      dollars."""
      self.balance += amount
      return self.balance

let c = newCustomer("Jack", 500)
print("Took 250, new balance is $1.".format(c.withdraw(250.0)))
print("Added 1337, new balance is $1.".format(c.deposit(1337.0)))


type Shape = ref object
  x, y: float
  description, author: string

# An example of a class
class Shape:
  def init(self, x, y):
    self.x = x
    self.y = y
    self.description = "This shape has not been described yet"
    self.author = "Nobody has claimed to make this shape yet"

  def area(self):
    return self.x * self.y

  def perimeter(self):
    return 2 * self.x + 2 * self.y

  def describe(self, text):
    self.description = text

  def authorName(self, text):
    self.author = text

  def scaleSize(self, scale):
    self.x = self.x * scale
    self.y = self.y * scale

let sh = newShape(5.0, 15.3)
print("Area is $1".format(sh.area()))
