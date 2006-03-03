{-# OPTIONS_GHC -fglasgow-exts #-}
module Transfer.Core.Print where

-- pretty-printer generated by the BNF converter

import Transfer.Core.Abs
import Data.Char
import Data.List (intersperse)

-- the top-level printing method
printTree :: Print a => a -> String
printTree = render . prt 0

type Doc = [ShowS] -> [ShowS]

doc :: ShowS -> Doc
doc = (:)

render :: Doc -> String
render d = rend 0 (map ($ "") $ d []) "" where
  rend i ss = case ss of
    "["      :ts -> showChar '[' . rend i ts
    "("      :ts -> showChar '(' . rend i ts
    "{"      :ts -> showChar '{' . new (i+1) . rend (i+1) ts
    "}" : ";":ts -> new (i-1) . space "}" . showChar ';' . new (i-1) . rend (i-1) ts
    "}"      :ts -> new (i-1) . showChar '}' . new (i-1) . rend (i-1) ts
    ";"      :ts -> showChar ';' . new i . rend i ts
    t  : "," :ts -> showString t . space "," . rend i ts
    t  : ")" :ts -> showString t . showChar ')' . rend i ts
    t  : "]" :ts -> showString t . showChar ']' . rend i ts
    t        :ts -> space t . rend i ts
    _            -> id
  new i   = showChar '\n' . replicateS (2*i) (showChar ' ') . dropWhile isSpace
  space t = showString t . (\s -> if null s then "" else (' ':s))

parenth :: Doc -> Doc
parenth ss = doc (showChar '(') . ss . doc (showChar ')')

concatS :: [ShowS] -> ShowS
concatS = foldr (.) id

concatD :: [Doc] -> Doc
concatD = foldr (.) id

unwordsD :: [Doc] -> Doc
unwordsD = concatD . intersperse (doc (showChar ' '))

replicateS :: Int -> ShowS -> ShowS
replicateS n f = concatS (replicate n f)

-- the printer class does the job
class Print a where
  prt :: Int -> a -> Doc

instance Print Char where
  prt _ s = doc (showChar '\'' . mkEsc '\'' s . showChar '\'')

instance Print String where
  prt _ s = doc (showChar '"' . concatS (map (mkEsc '"') s) . showChar '"')

mkEsc :: Char -> Char -> ShowS
mkEsc q s = case s of
  _ | s == q -> showChar '\\' . showChar s
  '\\'-> showString "\\\\"
  '\n' -> showString "\\n"
  '\t' -> showString "\\t"
  _ -> showChar s

prPrec :: Int -> Int -> Doc -> Doc
prPrec i j = if j<i then parenth else id


instance Print Integer where
  prt _ x = doc (shows x)


instance Print Double where
  prt _ x = doc (shows x)


instance Print (Tree c) where
  prt _i e = case e of
    Module decls -> prPrec _i 0 (concatD [prt 0 decls])
    DataDecl cident exp consdecls -> prPrec _i 0 (concatD [doc (showString "data") , prt 0 cident , doc (showString ":") , prt 0 exp , doc (showString "where") , doc (showString "{") , prt 0 consdecls , doc (showString "}")])
    TypeDecl cident exp -> prPrec _i 0 (concatD [prt 0 cident , doc (showString ":") , prt 0 exp])
    ValueDecl cident exp -> prPrec _i 0 (concatD [prt 0 cident , doc (showString "=") , prt 0 exp])
    ConsDecl cident exp -> prPrec _i 0 (concatD [prt 0 cident , doc (showString ":") , prt 0 exp])
    PCons cident patterns -> prPrec _i 0 (concatD [doc (showString "(") , prt 0 cident , prt 0 patterns , doc (showString ")")])
    PVar patternvariable -> prPrec _i 0 (concatD [prt 0 patternvariable])
    PRec fieldpatterns -> prPrec _i 0 (concatD [doc (showString "rec") , doc (showString "{") , prt 0 fieldpatterns , doc (showString "}")])
    PStr str -> prPrec _i 0 (concatD [prt 0 str])
    PInt n -> prPrec _i 0 (concatD [prt 0 n])
    FieldPattern cident pattern -> prPrec _i 0 (concatD [prt 0 cident , doc (showString "=") , prt 0 pattern])
    PVVar cident -> prPrec _i 0 (concatD [prt 0 cident])
    PVWild  -> prPrec _i 0 (concatD [doc (showString "_")])
    ELet letdefs exp -> prPrec _i 0 (concatD [doc (showString "let") , doc (showString "{") , prt 0 letdefs , doc (showString "}") , doc (showString "in") , prt 0 exp])
    ECase exp cases -> prPrec _i 0 (concatD [doc (showString "case") , prt 0 exp , doc (showString "of") , doc (showString "{") , prt 0 cases , doc (showString "}")])
    EAbs patternvariable exp -> prPrec _i 1 (concatD [doc (showString "\\") , prt 0 patternvariable , doc (showString "->") , prt 0 exp])
    EPi patternvariable exp0 exp1 -> prPrec _i 1 (concatD [doc (showString "(") , prt 0 patternvariable , doc (showString ":") , prt 0 exp0 , doc (showString ")") , doc (showString "->") , prt 0 exp1])
    EApp exp0 exp1 -> prPrec _i 3 (concatD [prt 3 exp0 , prt 4 exp1])
    EProj exp cident -> prPrec _i 4 (concatD [prt 4 exp , doc (showString ".") , prt 0 cident])
    ERecType fieldtypes -> prPrec _i 5 (concatD [doc (showString "sig") , doc (showString "{") , prt 0 fieldtypes , doc (showString "}")])
    ERec fieldvalues -> prPrec _i 5 (concatD [doc (showString "rec") , doc (showString "{") , prt 0 fieldvalues , doc (showString "}")])
    EVar cident -> prPrec _i 5 (concatD [prt 0 cident])
    EType  -> prPrec _i 5 (concatD [doc (showString "Type")])
    EStr str -> prPrec _i 5 (concatD [prt 0 str])
    EInteger n -> prPrec _i 5 (concatD [prt 0 n])
    EDouble d -> prPrec _i 5 (concatD [prt 0 d])
    EMeta tmeta -> prPrec _i 5 (concatD [prt 0 tmeta])
    LetDef cident exp -> prPrec _i 0 (concatD [prt 0 cident , doc (showString "=") , prt 0 exp])
    Case pattern exp0 exp1 -> prPrec _i 0 (concatD [prt 0 pattern , doc (showString "|") , prt 0 exp0 , doc (showString "->") , prt 0 exp1])
    FieldType cident exp -> prPrec _i 0 (concatD [prt 0 cident , doc (showString ":") , prt 0 exp])
    FieldValue cident exp -> prPrec _i 0 (concatD [prt 0 cident , doc (showString "=") , prt 0 exp])
    TMeta str -> prPrec _i 0 (doc (showString str))
    CIdent str -> prPrec _i 0 (doc (showString str))

instance Print [Decl] where
  prt _ es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ";") , prt 0 xs])
instance Print [ConsDecl] where
  prt _ es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ";") , prt 0 xs])
instance Print [Pattern] where
  prt _ es = case es of
   [] -> (concatD [])
   x:xs -> (concatD [prt 0 x , prt 0 xs])
instance Print [FieldPattern] where
  prt _ es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ";") , prt 0 xs])
instance Print [LetDef] where
  prt _ es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ";") , prt 0 xs])
instance Print [Case] where
  prt _ es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ";") , prt 0 xs])
instance Print [FieldType] where
  prt _ es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ";") , prt 0 xs])
instance Print [FieldValue] where
  prt _ es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ";") , prt 0 xs])
