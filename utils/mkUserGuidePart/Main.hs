module Main (main) where

import DynFlags
import Control.Monad (forM_)
import Types hiding (flag)
import Table
import Options

import System.IO

writeFileUtf8 :: FilePath -> String -> IO ()
writeFileUtf8 f txt = withFile f WriteMode (\ hdl -> hSetEncoding hdl utf8 >> hPutStr hdl txt)

-- | A ReStructuredText fragment
type ReST = String

main :: IO ()
main = do
  -- user's guide
  writeRestFile (usersGuideFile "what_glasgow_exts_does.gen.rst")
    $ whatGlasgowExtsDoes
  forM_ groups $ \(Group name _ theFlags) ->
    let fname = usersGuideFile $ "flags-"++name++".gen.rst"
    in writeRestFile fname (flagsTable theFlags)

  -- man page
  writeRestFile (usersGuideFile "all-flags.gen.rst") (flagsList groups)

usersGuideFile :: FilePath -> FilePath
usersGuideFile fname = "docs/users_guide/"++fname

writeRestFile :: FilePath -> ReST -> IO ()
writeRestFile fname content =
  writeFileUtf8 fname $ unlines
    [ ".. This file is generated by utils/mkUserGuidePart"
    , ""
    , content
    ]

whatGlasgowExtsDoes :: String
whatGlasgowExtsDoes = unlines
    $ [ ".. hlist::", ""]
    ++ map ((" * "++) . parseExt) glasgowExtsFlags
  where
    parseExt ext = inlineCode $ "-X" ++ show ext

-- | Generate a reference table of the given set of flags. This is used in
-- the user's guide.
flagsTable :: [Flag] -> ReST
flagsTable theFlags =
    table [50, 100, 30, 55]
          ["Flag", "Description", "Type", "Reverse"]
          (map flagRow theFlags)
  where
    flagRow flag =
        [ role "ghc-flag" (flagName flag)
        , flagDescription flag
        , type_
        , role "ghc-flag" (flagReverse flag)
        ]
      where
        type_ = case flagType flag of
                  DynamicFlag         -> "dynamic"
                  DynamicSettableFlag -> "dynamic/``:set``"
                  ModeFlag            -> "mode"

-- | Place the given text in an ReST inline code element.
inlineCode :: String -> ReST
inlineCode s = "``" ++ s ++ "``"

-- | @role "hi" "Hello world"@ produces the ReST inline role element
-- @:hi:`Hello world`@.
role :: String -> String -> ReST
role _ "" = ""
role r c  = concat [":",r,":`",c,"`"]

heading :: Char -> String -> ReST
heading chr title = unlines
    [ title
    , replicate (length title) chr
    , ""
    ]

-- | Generate a listing of all the flags known to GHC.
-- Used in the man page.
flagsList :: [Group] -> ReST
flagsList grps = unlines $
    map doGroup grps ++ map flagDescriptions grps
  where
    doGroup grp = unlines
      [ grpTitle grp
      , "    " ++ unwords (map (inlineCode . flagName) (grpFlags grp))
      , ""
      ]

-- | Generate a definition list of the known flags.
-- Used in the man page.
flagDescriptions :: Group -> ReST
flagDescriptions (Group _ title fs) =
    unlines $ [ heading '~' title ] ++ map doFlag fs
  where
    doFlag flag =
      unlines $ [ inlineCode (flagName flag)
                , "    " ++ flagDescription flag
                ]
