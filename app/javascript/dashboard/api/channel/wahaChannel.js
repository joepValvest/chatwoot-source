/* global axios */
import ApiClient from '../ApiClient';

class WahaChannelApi extends ApiClient {
  constructor() {
    super('channels/waha_channels', { accountScoped: true });
  }

  create(params) {
    return axios.post(this.url, {
      waha_channel: params,
    });
  }

  update(id, params) {
    return axios.put(`${this.url}/${id}`, {
      waha_channel: params,
    });
  }
}

export default new WahaChannelApi();
