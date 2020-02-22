module AppleIapUtil
  class Config < Struct(
    :shared_password,
    keyword_init: true
  )
  end
end
