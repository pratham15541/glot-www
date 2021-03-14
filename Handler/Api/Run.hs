{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module Handler.Api.Run where

import Import
import qualified Data.Aeson as Aeson
import qualified Util.Handler as HandlerUtils
import qualified Handler.Run as RunHandler
import qualified GHC.Generics as GHC
import qualified Glot.Language

import Data.Function ((&))




getApiRunLanguagesR :: Handler Value
getApiRunLanguagesR = do
    App{..} <- getYesod
    renderUrl <- getUrlRender
    languageConfigs
        & filter Glot.Language.isRunnable
        & map Glot.Language.language
        & map (toRunLanguage renderUrl)
        & Aeson.toJSON
        & pure


data RunLanguage = RunLanguage
    { name :: Text
    , url :: Text
    }
    deriving (Show, GHC.Generic)

instance Aeson.ToJSON RunLanguage


toRunLanguage :: (Route App -> Text) -> Glot.Language.Language -> RunLanguage
toRunLanguage renderUrl language =
    RunLanguage
        { name = Glot.Language.toText language
        , url = renderUrl (ApiRunVersionsR language)
        }


getApiRunVersionsR :: Glot.Language.Language -> Handler Value
getApiRunVersionsR language = do
    renderUrl <- getUrlRender
    let version = "latest"
    RunVersion
        { version = version
        , url = renderUrl (ApiRunR language version)
        }
        & Aeson.toJSON
        & pure


data RunVersion = RunVersion
    { version :: Text
    , url :: Text
    }
    deriving (Show, GHC.Generic)

instance Aeson.ToJSON RunVersion



postApiRunR :: Glot.Language.Language -> Text -> Handler Value
postApiRunR language _ = do
    maybeApiUser <- HandlerUtils.lookupApiUser
    case fmap apiUserUserId maybeApiUser of
        Just _ ->
            RunHandler.postRunR language

        Nothing ->
            sendResponseStatus status401 $ object ["message" .= Aeson.String "A valid access token is required to run code"]


getApiRunR :: Glot.Language.Language -> Text -> Handler Value
getApiRunR _ _ = do
    sendResponseStatus status405 $ Aeson.object [ "message" .= Aeson.String "Do a POST request instead of GET to run code" ]
