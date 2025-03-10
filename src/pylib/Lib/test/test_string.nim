

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


    def test_SafeTemplate(self):
        template eq(a, b) = self.assertEqual(a, b)

        s = Template("$who likes ${what} for ${meal}")
        eq(s.safe_substitute(dict(who="tim")), "tim likes ${what} for ${meal}")
        eq(s.safe_substitute(dict(what="ham")), "$who likes ham for ${meal}")
        eq(s.safe_substitute(dict(what="ham", meal="dinner")),
           "$who likes ham for dinner")
        eq(s.safe_substitute(dict(who="tim", what="ham")),
           "tim likes ham for ${meal}")
        eq(s.safe_substitute(dict(who="tim", what="ham", meal="dinner")),
           "tim likes ham for dinner")

    self.test_regular_templates_with_braces()
    self.test_regular_templates_with_upper_case()
    self.test_SafeTemplate()

