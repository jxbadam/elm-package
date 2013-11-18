{-# LANGUAGE DeriveDataTypeable, TemplateHaskell #-}
module Model.Version where

import           Control.Applicative
import           Data.Binary
import           Data.Char              (isDigit)
import qualified Data.List              as List
import qualified Data.SafeCopy          as SC
import           Data.Typeable

-- Data representation

data Version = V [Int] String
    deriving (Typeable,Eq)

$(SC.deriveSafeCopy 0 'SC.base ''Version)

instance Ord Version where
  compare (V ns tag) (V ns' tag') =
      case compare ns ns' of
        EQ -> reverseOrder tag tag'
        cmp -> cmp

reverseOrder v1 v2 =
    case compare v1 v2 of { LT -> GT ; EQ -> EQ ; GT -> LT }

instance Show Version where
  show (V ns tag) =
      List.intercalate "." (map show ns) ++ if null tag then "" else "-" ++ tag

instance Binary Version where
  get = V <$> get <*> get
  put (V ns tag) = do put ns
                      put tag

tagless :: Version -> Bool
tagless (V _ tag) = null tag

fromString :: String -> Maybe Version
fromString version = V <$> splitNumbers possibleNumbers <*> tag
    where
      (possibleNumbers, possibleTag) = break ((==) '-') version

      tag = case possibleTag of
              "" -> Just ""
              '-':rest -> Just rest
              _ -> Nothing

      splitNumbers :: String -> Maybe [Int]
      splitNumbers ns =
          case span isDigit ns of
            ("", _) -> Nothing
            (number, []) -> Just [read number]
            (number, '.':rest) -> (read number :) <$> splitNumbers rest
            _ -> Nothing
