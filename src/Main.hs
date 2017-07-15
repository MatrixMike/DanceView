{-# LANGUAGE DuplicateRecordFields     #-}
{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE FlexibleInstances         #-}
{-# LANGUAGE GADTs                     #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE OverloadedStrings         #-}
{-# LANGUAGE RecordWildCards           #-}
{-# LANGUAGE ScopedTypeVariables       #-}
{-# LANGUAGE TypeFamilies              #-}
{-# LANGUAGE TypeOperators             #-}
{-# LANGUAGE UndecidableInstances      #-}

-- TODO:
--
-- Use "start" and "end" times.
-- Body Rotation Options?
-- Filter Out Non-Moving People?
--
-- TODO: Print time
--
-- TODO: It currently crashes when it ends. We should stop the animation (or
-- loop it) when we run out of time.
--
--
-- TOOD:
--   - If we're going for POAM we need to have a bunch of configurations that
--   let us design a particular item and then emit a file of the right type.
--
--   Basically, we need to cut off the thing. Then it works.
--
-- TODO: Calculate max number of cols we can have depending on the width we've
-- asked for
--
-- TODO: Visible body-part count filter
--
-- TODO: Use Rasterific to generate some Gifs
--
-- TODO: Person Re-Identification

module Main where


import           Data
import           Montage
import           Animation
import           Options.Generic
import           Data.Maybe
import           Data.Aeson
import           System.FilePath.Find
import           Data.String.Conv       (toS)
import qualified Data.ByteString        as B


main :: IO ()
main = do
    opts :: Options <- unwrapRecord "DanceView - Watch the poses generated by pose networks."

    jsonFiles <- find (depth ==? 0) (extension ==? ".json") (sourceDirectory opts)
    frames'    <- mapM readFrame jsonFiles

    -- Ensure there are people in every frame.
    let frames = filter (not . null . people) frames'

    case opts of
      DoAnimation {..} -> doAnimation frames opts
      DoMontage   {..} -> doMontage   frames opts


readFrame :: FilePath -> IO Frame
readFrame f = do
    -- Note: We strictly read here because otherwise we die from too many open
    -- files. There's probably a nicer way to do this, but hey.
    file <- B.readFile f

    return $ fromMaybe (error $ "Couldn't load Frame from file: " ++ show file)
                       (decode' (toS file)) 

