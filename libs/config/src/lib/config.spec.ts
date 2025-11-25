import { config } from './config';

describe('config', () => {
  it('should have api configuration', () => {
    expect(config.api).toBeDefined();
    expect(config.api.port).toBeDefined();
    expect(config.api.host).toBeDefined();
  });

  it('should have web configuration', () => {
    expect(config.web).toBeDefined();
    expect(config.web.port).toBeDefined();
    expect(config.web.apiUrl).toBeDefined();
  });

  it('should have database configuration', () => {
    expect(config.database).toBeDefined();
    expect(config.database.url).toBeDefined();
  });
});
