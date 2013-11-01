{-# LANGUAGE OverloadedStrings #-}

module Network.Wai.Handler.Warp.Header where

import Data.Array
import Data.Array.ST
import Network.HTTP.Types
import Network.Wai.Handler.Warp.Types

----------------------------------------------------------------

-- | Array for a set of HTTP headers.
type IndexedHeader = Array Int (Maybe HeaderValue)

----------------------------------------------------------------

indexRequestHeader :: RequestHeaders -> IndexedHeader
indexRequestHeader hdr = traverseHeader hdr requestMaxIndex requestKeyIndex

idxContentLength,idxTransferEncoding,idxExpect :: Int
idxConnection,idxRange,idxHost :: Int
idxContentLength    = 0
idxTransferEncoding = 1
idxExpect           = 2
idxConnection       = 3
idxRange            = 4
idxHost             = 5

-- | The size for 'IndexedHeader' for HTTP Request.
requestMaxIndex :: Int
requestMaxIndex     = 5

requestKeyIndex :: HeaderName -> Int
requestKeyIndex "content-length"    = idxContentLength
requestKeyIndex "transfer-encoding" = idxTransferEncoding
requestKeyIndex "expect"            = idxExpect
requestKeyIndex "connection"        = idxConnection
requestKeyIndex "range"             = idxRange
requestKeyIndex "host"              = idxHost
requestKeyIndex _                   = -1

-- | Default 'IndexedHeader' for HTTP Request.
--   All valuers are 'Nothing' by default.
--   They correspond to \"Content-Length\", \"Transfer-Encoding\",
--   \"Expect\", \"Connection\", \"Range\", and \"Host\".
defaultIndexRequestHeader :: IndexedHeader
defaultIndexRequestHeader = array (0,requestMaxIndex) [(i,Nothing)|i<-[0..requestMaxIndex]]

----------------------------------------------------------------

indexResponseHeader :: ResponseHeaders -> IndexedHeader
indexResponseHeader hdr = traverseHeader hdr responseMaxIndex responseKeyIndex

idxServer :: Int
--idxContentLength = 0
idxServer        = 1

-- | The size for 'IndexedHeader' for HTTP Response.
responseMaxIndex :: Int
responseMaxIndex = 1

responseKeyIndex :: HeaderName -> Int
responseKeyIndex "content-length" = idxContentLength
responseKeyIndex "server"         = idxServer
responseKeyIndex _                = -1

----------------------------------------------------------------

traverseHeader :: [Header] -> Int -> (HeaderName -> Int) -> IndexedHeader
traverseHeader hdr maxidx getIndex = runSTArray $ do
    arr <- newArray (0,maxidx) Nothing
    mapM_ (insert arr) hdr
    return arr
  where
    insert arr (key,val)
      | idx == -1 = return ()
      | otherwise = writeArray arr idx (Just val)
      where
        idx = getIndex key