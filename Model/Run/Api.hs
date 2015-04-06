{-# LANGUAGE OverloadedStrings, DeriveGeneric #-}
module Model.Run.Api (
    addUser,
    setUserToken,
    runSnippet
) where

import Import.NoFoundation hiding (error, stderr, stdout)
import Util.Api (createUser, updateUser)
import Data.Aeson (decode)
import Data.Maybe (fromJust)
import Util.Http (httpPost)
import Settings.Environment (runApiBaseUrl, runApiAdminToken)
import qualified Data.ByteString.Lazy as L

data InternalRunResult = InternalRunResult {
    stdout :: Text,
    stderr :: Text,
    error :: Text
} deriving (Show, Generic)

instance FromJSON InternalRunResult

addUser :: Text -> IO Text
addUser userToken = do
    url <- createUserUrl <$> runApiBaseUrl
    adminToken <- runApiAdminToken
    createUser url adminToken userToken

setUserToken :: Text -> Text -> IO ()
setUserToken userId userToken = do
    url <- (updateUserUrl userId) <$> runApiBaseUrl
    adminToken <- runApiAdminToken
    updateUser url adminToken userToken

toRunResultTuple :: InternalRunResult -> (Text, Text, Text)
toRunResultTuple x = (stdout x, stderr x, error x)

runSnippet :: Text -> Text -> L.ByteString -> Text -> IO (Text, Text, Text)
runSnippet lang version payload authToken = do
    apiUrl <- (runSnippetUrl lang version) <$> runApiBaseUrl
    body <- httpPost apiUrl (Just authToken) payload
    let mJson = decode body :: Maybe InternalRunResult
    return $ toRunResultTuple $ fromJust mJson

createUserUrl :: String -> String
createUserUrl baseUrl = baseUrl ++ "/admin/users"

updateUserUrl :: Text -> String -> String
updateUserUrl userId baseUrl = baseUrl ++ "/admin/users/" ++ unpack userId

runSnippetUrl :: Text -> Text -> String -> String
runSnippetUrl lang version baseUrl =
    baseUrl ++ "/languages/" ++ unpack lang ++ "/" ++ unpack version