test "Class macro":
  type Customer = ref object
    name: string
    balance: float
  checkpoint "Class creation"
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
  checkpoint "Initialisation"
  let c = newCustomer("Daniil", 500)
  checkpoint "Fields"
  check c.name == "Daniil"
  check c.balance == 500
  checkpoint "'Methods' (procedures)"
  check c.withdraw(250.0) == 250.0
  check c.deposit(1337.0) == 1587.0