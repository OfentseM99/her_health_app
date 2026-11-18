window.herHealthPasskeys = {
  isAvailable: async function () {
    try {
      if (!window.PublicKeyCredential) return false;

      return await PublicKeyCredential
        .isUserVerifyingPlatformAuthenticatorAvailable();
    } catch (_) {
      return false;
    }
  },

  bufferToBase64Url: function (buffer) {
    const bytes = new Uint8Array(buffer);
    let binary = "";

    for (let i = 0; i < bytes.length; i++) {
      binary += String.fromCharCode(bytes[i]);
    }

    return btoa(binary)
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/g, "");
  },

  serializeCredential: function (credential) {
    const response = credential.response;

    const result = {
      id: credential.id,
      rawId: this.bufferToBase64Url(credential.rawId),
      type: credential.type,
      response: {
        clientDataJSON: this.bufferToBase64Url(
          response.clientDataJSON
        ),
      },
      clientExtensionResults:
        credential.getClientExtensionResults
          ? credential.getClientExtensionResults()
          : {},
    };

    if (credential.authenticatorAttachment) {
      result.authenticatorAttachment =
        credential.authenticatorAttachment;
    }

    if ("attestationObject" in response) {
      result.response.attestationObject =
        this.bufferToBase64Url(response.attestationObject);

      if (response.getTransports) {
        result.response.transports = response.getTransports();
      }
    } else {
      result.response.authenticatorData =
        this.bufferToBase64Url(response.authenticatorData);

      result.response.signature =
        this.bufferToBase64Url(response.signature);

      result.response.userHandle = response.userHandle
        ? this.bufferToBase64Url(response.userHandle)
        : null;
    }

    return JSON.stringify(result);
  },

  register: async function (optionsJson) {
    const options = JSON.parse(optionsJson);

    let publicKey;

    if (PublicKeyCredential.parseCreationOptionsFromJSON) {
      publicKey =
        PublicKeyCredential.parseCreationOptionsFromJSON(options);
    } else {
      publicKey = {
        ...options,
        challenge: this.base64UrlToBuffer(options.challenge),
        user: {
          ...options.user,
          id: this.base64UrlToBuffer(options.user.id),
        },
        excludeCredentials:
          (options.excludeCredentials || []).map((credential) => ({
            ...credential,
            id: this.base64UrlToBuffer(credential.id),
          })),
      };
    }

    const credential = await navigator.credentials.create({
      publicKey: publicKey,
    });

    if (!credential) {
      throw new Error("No device credential was created.");
    }

    return this.serializeCredential(credential);
  },

  authenticate: async function (optionsJson) {
    const options = JSON.parse(optionsJson);

    let publicKey;

    if (PublicKeyCredential.parseRequestOptionsFromJSON) {
      publicKey =
        PublicKeyCredential.parseRequestOptionsFromJSON(options);
    } else {
      publicKey = {
        ...options,
        challenge: this.base64UrlToBuffer(options.challenge),
        allowCredentials:
          (options.allowCredentials || []).map((credential) => ({
            ...credential,
            id: this.base64UrlToBuffer(credential.id),
          })),
      };
    }

    const credential = await navigator.credentials.get({
      publicKey: publicKey,
    });

    if (!credential) {
      throw new Error("Device authentication was cancelled.");
    }

    return this.serializeCredential(credential);
  },

  base64UrlToBuffer: function (value) {
    const padding = "=".repeat((4 - (value.length % 4)) % 4);

    const base64 = (value + padding)
      .replace(/-/g, "+")
      .replace(/_/g, "/");

    const raw = atob(base64);

    return Uint8Array.from(
      raw,
      (character) => character.charCodeAt(0)
    ).buffer;
  },
};
