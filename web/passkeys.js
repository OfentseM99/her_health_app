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

    return JSON.stringify(credential);
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

    return JSON.stringify(credential);
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