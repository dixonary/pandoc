{-# LANGUAGE OverloadedStrings #-}
module Tests.Readers.Man (tests) where

import Prelude
import Data.Text (Text)
import Test.Tasty
import Tests.Helpers
import Text.Pandoc
import Text.Pandoc.Arbitrary ()
import Text.Pandoc.Builder
import Text.Pandoc.Readers.Man

man :: Text -> Pandoc
man = purely $ readMan def

infix 4 =:
(=:) :: ToString c
     => String -> (Text, c) -> TestTree
(=:) = test man

tests :: [TestTree]
tests = [
  -- .SH "HEllo bbb" "aaa"" as"
  testGroup "Macros" [
      "Bold" =:
      ".B foo"
      =?> para (strong "foo")
    , "Italic" =:
      ".I bar\n"
      =?> para (emph "bar")
    , "BoldItalic" =:
      ".BI foo bar"
      =?> para (strong (str "foo") <> emph (str "bar"))
    , "H1" =:
      ".SH The header\n"
      =?> header 1 (text "The header")
    , "H2" =:
      ".SS \"The header 2\""
      =?> header 2 (text "The header 2")
    , "Macro args" =:
      ".B \"single arg with \"\"Q\"\"\""
      =?> (para $ strong $ text "single arg with \"Q\"")
    , "comment" =:
      ".\\\"bla\naaa"
      =?> (para $ str "aaa")
    , "link" =:
      ".BR aa (1)"
      =?> para (text "aa(1)")
    ],
  testGroup "Escapes" [
      "fonts" =:
      "aa\\fIbb\\fRcc"
      =?> (para $ str "aa" <> (emph $ str "bb") <> str "cc")
    , "skip" =:
      "a\\%\\{\\}\\\n\\:b\\0"
      =?> (para $ str "ab")
    , "replace" =:
      "\\-\\ \\\\\\[lq]\\[rq]\\[em]\\[en]\\*(lq\\*(rq"
      =?> (para $ text "- \\“”—–“”")
    , "replace2" =:
      "\\t\\e\\`\\^\\|\\'" =?> (para $ text "\\`  `")
    , "comment  with \\\"" =:
      "Foo \\\" bar\n" =?> (para $ text "Foo")
    , "comment with \\#" =:
      "Foo\\#\nbar\n" =?> (para $ text "Foobar")
    , "two letter escapes" =:
      "\\(oA\\(~O" =?> (para $ text "ÅÕ")
    , "bracketed escapes" =:
      "\\[oA]\\[~O]\\[Do]\\[Ye]\\[product]" =?> (para $ text "ÅÕ$¥∏")
    , "unicode escapes" =:
      "\\[u2020]" =?> (para $ text "†")
    , "unicode escapes (combined)" =:
      "\\[u0075_u0301]" =?> (para $ text "ú")
    ],
  testGroup "Lists" [
      "bullet" =:
      ".IP \"\\[bu]\"\nfirst\n.IP \"\\[bu]\"\nsecond"
      =?> bulletList [para $ str "first", para $ str "second"]
    , "ordered" =:
      ".IP 2 a\nfirst\n.IP 3 a\nsecond"
      =?> orderedListWith (2,Decimal,DefaultDelim) [para $ str "first", para $ str "second"]
    , "upper" =:
      ".IP A) a\nfirst\n.IP B) a\nsecond"
      =?> orderedListWith (1,UpperAlpha,OneParen) [para $ str "first", para $ str "second"]
    , "nested" =:
      ".IP \"\\[bu]\"\nfirst\n.RS\n.IP \"\\[bu]\"\n1a\n.IP \"\\[bu]\"\n1b\n.RE"
      =?> bulletList [(para $ str "first") <> (bulletList [para $ str "1a", para $ str "1b"])]
    , "change in list style" =:
      ".IP \\[bu]\nfirst\n.IP 1\nsecond"
      =?> bulletList [para (str "first")] <>
            orderedListWith (1,Decimal,DefaultDelim) [para (str "second")]
    ],
  testGroup "CodeBlocks" [
      "cb1"=:
      ".nf\naa\n\tbb\n.fi"
      =?> codeBlock "aa\n\tbb"
    ]
  ]
