

import ./import_utils
importTestPyLib string
pyimport unittest

var self = newTestCase()

block test_capwords:
        check "hello δδ".capwords == "Hello Δδ" ## support Unicode
        check "01234".capwords == "01234"

        self.assertEqual(string.capwords("abc def ghi"), "Abc Def Ghi")
        self.assertEqual(string.capwords("abc\tdef\nghi"), "Abc Def Ghi")
        self.assertEqual(string.capwords("abc\t   def  \nghi"), "Abc Def Ghi")
        self.assertEqual(string.capwords("ABC DEF GHI"), "Abc Def Ghi")
        self.assertEqual(string.capwords("ABC-DEF-GHI", "-"), "Abc-Def-Ghi")
        self.assertEqual(string.capwords("ABC-def DEF-ghi GHI"), "Abc-def Def-ghi Ghi")
        self.assertEqual(string.capwords("   aBc  DeF   "), "Abc Def")
        self.assertEqual(string.capwords("\taBc\tDeF\t"), "Abc Def")
        self.assertEqual(string.capwords("\taBc\tDeF\t", "\t"), "\tAbc\tDef\t")

block TestTemplate:
    var
      s: Template
    block test_regular_templates:
        s = Template("$who likes to eat a bag of $what worth $$100")

        self.assertEqual(s.substitute(dict(who="tim", what="ham")),
                         "tim likes to eat a bag of ham worth $100")
        #self.assertRaises(KeyError, s.substitute, dict(who="tim"))
        #self.assertRaises(TypeError, Template.substitute)

        expect KeyError:
            let d = dict(who="tim")
            discard s.substitute(d)

    template eq(a, b) =
      mixin self; self.assertEqual(a, b)
    template raises(t, c; args: varargs[untyped]) =
      mixin self; self.assertRaises(t, c, args)

    def test_regular_templates_with_braces(self):
        s = Template("$who likes ${what} for ${meal}")
        d = dict(who="tim", what="ham", meal="dinner")
        self.assertEqual(s.substitute(d), "tim likes ham for dinner")
        #self.assertRaises(KeyError, s.substitute,
        #                 dict(who="tim", what="ham"))
        expect KeyError:
          discard s.substitute dict(who="tim", what="ham")

    def test_regular_templates_with_upper_case(self):
        s = Template("$WHO likes ${WHAT} for ${MEAL}")
        d = dict(WHO="tim", WHAT="ham", MEAL="dinner")
        self.assertEqual(s.substitute(d), "tim likes ham for dinner")

    def test_stringification(self):

        s = Template("tim has eaten $count bags of ham today")
        d = dict(count=7)
        eq(s.substitute(d), "tim has eaten 7 bags of ham today")
        eq(s.safe_substitute(d), "tim has eaten 7 bags of ham today")
        s = Template("tim has eaten ${count} bags of ham today")
        eq(s.substitute(d), "tim has eaten 7 bags of ham today")

    def test_tupleargs(self):

        s = Template("$who ate ${meal}")
        d = dict(who=("tim", "fred"), meal=("ham", "kung pao"))
        eq(s.substitute(d), "('tim', 'fred') ate ('ham', 'kung pao')")
        eq(s.safe_substitute(d), "('tim', 'fred') ate ('ham', 'kung pao')")

    def test_SafeTemplate(self):

        s = Template("$who likes ${what} for ${meal}")
        eq(s.safe_substitute(dict(who="tim")), "tim likes ${what} for ${meal}")
        eq(s.safe_substitute(dict(what="ham")), "$who likes ham for ${meal}")
        eq(s.safe_substitute(dict(what="ham", meal="dinner")),
           "$who likes ham for dinner")
        eq(s.safe_substitute(dict(who="tim", what="ham")),
           "tim likes ham for ${meal}")
        eq(s.safe_substitute(dict(who="tim", what="ham", meal="dinner")),
           "tim likes ham for dinner")

    def test_keyword_arguments(self):

        s = Template("$who likes $what")
        eq(s.substitute(who="tim", what="ham"), "tim likes ham")
        eq(s.substitute(dict(who="tim"), what="ham"), "tim likes ham")
        eq(s.substitute(dict(who="fred", what="kung pao"),
                        who="tim", what="ham"),
           "tim likes ham")
        s = Template("the mapping is $mapping")
        eq(s.substitute(dict(foo="none"), mapping="bozo"),
           "the mapping is bozo")
        eq(s.substitute(dict(mapping="one"), mapping="two"),
           "the mapping is two")

        s = Template("the self is $self")
        eq(s.substitute(self="bozo"), "the self is bozo")

    def test_keyword_arguments_safe(self):


        s = Template("$who likes $what")
        eq(s.safe_substitute(who="tim", what="ham"), "tim likes ham")
        eq(s.safe_substitute(dict(who="tim"), what="ham"), "tim likes ham")
        eq(s.safe_substitute(dict(who="fred", what="kung pao"),
                        who="tim", what="ham"),
           "tim likes ham")
        s = Template("the mapping is $mapping")
        eq(s.safe_substitute(dict(foo="none"), mapping="bozo"),
           "the mapping is bozo")
        eq(s.safe_substitute(dict(mapping="one"), mapping="two"),
           "the mapping is two")
        d = dict(mapping="one")
        raises(TypeError, s.substitute, d, {})
        raises(TypeError, s.safe_substitute, d, {})

        s = Template("the self is $self")
        eq(s.safe_substitute(self="bozo"), "the self is bozo")

    #[
    def test_delimiter_override(self):


        class AmpersandTemplate(Template):
            delimiter = "&"
        s = AmpersandTemplate("this &gift is for &{who} &&")
        eq(s.substitute(gift="bud", who="you"), "this bud is for you &")
        raises(KeyError, s.substitute)
        eq(s.safe_substitute(gift="bud", who="you"), "this bud is for you &")
        eq(s.safe_substitute(), "this &gift is for &{who} &")
        s = AmpersandTemplate("this &gift is for &{who} &")
        raises(ValueError, s.substitute, dict(gift="bud", who="you"))
        eq(s.safe_substitute(), "this &gift is for &{who} &")

        class PieDelims(Template):
            delimiter = "@"
        s = PieDelims("@who likes to eat a bag of @{what} worth $100")
        self.assertEqual(s.substitute(dict(who="tim", what="ham")),
                         "tim likes to eat a bag of ham worth $100")
    ]#

    def test_is_valid(self):

        s = Template("$who likes to eat a bag of ${what} worth $$100")
        self.assertTrue(s.is_valid())

        s = Template("$who likes to eat a bag of ${what} worth $100")
        self.assertFalse(s.is_valid())

        #[
        # if the pattern has an unrecognized capture group,
        # it should raise ValueError like substitute and safe_substitute do
        class BadPattern(Template):
            pattern = r"""
            (?P<badname>.*)                  |
            (?P<escaped>@{2})                   |
            @(?P<named>[_a-z][._a-z0-9]*)       |
            @{(?P<braced>[_a-z][._a-z0-9]*)}    |
            (?P<invalid>@)                      |
            """
        s = BadPattern("@bag.foo.who likes to eat a bag of @bag.what")
        self.assertRaises(ValueError, s.is_valid)
        ]#

    def test_get_identifiers(self):
        ls = ["who", "what"]

        s = Template("$who likes to eat a bag of ${what} worth $$100")
        ids = s.get_identifiers()

        eq(ids, ls)

        # repeated identifiers only included once
        s = Template("$who likes to eat a bag of ${what} worth $$100; ${who} likes to eat a bag of $what worth $$100")
        ids = s.get_identifiers()
        eq(ids, ls)

        # invalid identifiers are ignored
        s = Template("$who likes to eat a bag of ${what} worth $100")
        ids = s.get_identifiers()
        eq(ids, ls)

        #[
        # if the pattern has an unrecognized capture group,
        # it should raise ValueError like substitute and safe_substitute do
        class BadPattern(Template):
            pattern = r"""
            (?P<badname>.*)                  |
            (?P<escaped>@{2})                   |
            @(?P<named>[_a-z][._a-z0-9]*)       |
            @{(?P<braced>[_a-z][._a-z0-9]*)}    |
            (?P<invalid>@)                      |
            """
        s = BadPattern("@bag.foo.who likes to eat a bag of @bag.what")
        self.assertRaises(ValueError, s.get_identifiers)
        ]#

    self.test_regular_templates_with_braces()
    self.test_regular_templates_with_upper_case()
    self.test_stringification()
    self.test_tupleargs()
    self.test_SafeTemplate()

    self.test_keyword_arguments()
    self.test_keyword_arguments_safe()

    #self.test_delimiter_override()
    self.test_is_valid()
    self.test_get_identifiers()

